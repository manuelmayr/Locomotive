require :pp 

include Locomotive::RelAlgAst
include Locomotive::RelationalAlgebra::Types
include Locomotive::RelationalAlgebra::Exceptions
include Locomotive::RelationalAlgebra::Attributes

module Locomotive

module RelationalAlgebra

module Operators

#
# The Schema contains the attributes
# and its associated types.
# Each operator of the relational algebra
# contains a schema.
#
class Schema
  include Locomotive::XML
  def_node :_schema_, :col

  protected

  attr_accessor :schema
  def_sig :schema=, { Attribute => [Type] }
  
  # check if there are duplicates in the schemas
  def duplicates?(schema)
    (self.attributes + schema.attributes).length >
    (self.attributes + schema.attributes).uniq.length
  end
  def_sig :duplicates?, Schema

  public

  def initialize(hash)
    self.schema = hash
  end

  def attributes
    schema.keys
  end

  def attributes?(attributes)
    attributes.all? { |attr| self.attributes.member? attr }
  end
  def_sig :attributes?, [Attribute]

  # merges two schemas, given that there are
  # no duplicate keys
  def +(schm)
    if duplicates?(schm)
      raise Duplicates,
            "Found duplicates in #{self.attributes} " \
            "and #{schm.attributes}."
    end
    # create a new schema
    Schema.new(schema.merge(schm.schema))
  end
  def_sig :+, Schema

  def []=(attr,types)
    schema[attr] = types
  end
  def_sig :[]=, Attribute, [Type]

  def method_missing(mtd, *params, &block)
    if schema.respond_to? mtd
      schema.send(mtd, *params, &block)
    else
      super.method_missing(mtd, *params, &block)
    end
  end

  def to_xml
    _schema_ do
      self.schema.collect do |attr,types|
        col :name => attr.to_xml,
            :type => types.collect { |ty| ty.to_xml }.join(",")
      end.join
    end
  end

  def clone
    Schema.new( self.schema.clone )
  end
end

# represents a variant operator of the
# relational algebra
class Operator < RelAlgAstNode
  include Locomotive::XML
  def_node :node, :content, :column, :edge

  attr_accessor :schema
  def_sig :schema=, Schema

  def initialize
    raise AbstractClassError,
          "#{self.class} is an abstract class" if self.class == Operator
    self.schema = Schema.new({})
  end

  def xml_schema
    self.schema.to_xml
  end

  def xml_content
    content()
  end

  def xml_kind
    self.class.to_s.split("::").last.downcase.to_sym
  end

  def to_xml
    cont_list = [ xml_schema,
                  xml_content ]

    cont_list << edge(:to => left_child.ann_xml_id) if has_left_child? and left_child.respond_to? :ann_xml_id
    cont_list << edge(:to => right_child.ann_xml_id) if has_right_child? and right_child.respond_to? :ann_xml_id

    node  :id => ann_xml_id, :kind => xml_kind do
      cont_list.join
    end
  end

  # returns all free variables in this plan
  def free
    # attention: for convenience we use
    # the underlying ast framework
    fv = []
    fv += left_child.free if has_left_child?
    fv += right_child.free if has_right_child?
    fv
  end

  # returns all bound variables in this plan
  def bound
    # attention: for convenience we use
    #  the underlying ast framework
    bv = []
    bv += left_child.bound if has_left_child?
    bv += right_child.bound if has_right_child?
    bv
  end
end

#
# A leaf doesn't have any child
#
class Leaf < Operator
#  undef left_child=
#  undef left_child
#  undef has_left_child?
#  undef right_child=
#  undef right_child
#  undef has_right_child?
  def initialize()
    raise AbstractClassError,
          "#{self.class} is an abstract class" if self.class == Leaf
    super()
  end

  def set(var,plan)
    self.clone
  end
end

#
# An unary Operator has exactly one child
#
class Unary < Operator
  # undefine all methods to access
  # the right child
#  undef right_child=
#  undef right_child
#  undef has_right_child?

  # since we have only one child for this
  # type of operators, we define a shortcut
  alias :child :left_child
  alias :child= :left_child=
  def_sig :child=, Operator

  alias :child? :has_left_child?

  def initialize(op)
    raise AbstractClassError,
          "#{self.class} is an abstract class" if self.class == Unary
    super()
    self.child = op
  end
end

class Cast < Unary
  def_node :_type_

  attr_accessor :res,
                :type,
                :item 
  def_sig :res, Attribute
  def_sig :type, Type
  def_sig :item, Attribute

  def initialize(op, res, type, item)
    self.res,
    self.type,
    self.item = res, type, item
    super(op)
  end

  def child=(op)
    unless op.schema.attributes?([item])
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{item}."
    end
    self.schema = op.schema + { self.res => [self.type] }
    super(op)
  end

  def xml_content
    content do
      column :name => res.to_xml, :new => true
      column :name => item.to_xml, :new => false
      _type_ :name => type.to_xml
    end
  end

  def clone
    Cast.new(
      child.clone,
      res.clone,
      type.clone,
      item.clone)
  end

  def set(var,plan)
    Cast.new(
      child.set(var,plan),
      res.clone,
      type.clone,
      item.clone)
  end
end

#
# A binary operator has exactly two children
# 
class Binary < Operator
  # getter and setters for left and
  # right children by defining shortcuts
  alias :left :left_child
  alias :right :right_child
  alias :left? :has_left_child?
  alias :right? :has_right_child?

  #alias :left= :left_child=
  #def_sig :left=, Operator
  #alias :right= :right_child=
  #def_sig :right=, Operator

  def left_and_right(op1, op2)
    self.left_child = op1
    self.right_child = op2 
  end

  def initialize(op1, op2)
    raise AbstractClassError,
          "#{self.class} is an abstract class" if self.class == Binary
    super()
    left_and_right(op1,op2)
  end
end

class Variable < Leaf

  @id_pool = []
  class << self
    attr_accessor :id_pool
    
    def new_variable
      new_id = Variable.id_pool.max + 1
      Variable.id_pool << new_id
      Variable.new(new_id)
    end
  end

  attr_accessor :id, :items
  def_sig :id=, Integer
  def_sig :items=, [Attribute]
  def_node :variable


  def initialize(id, *items)
    self.id,
    self.items = id, items
    Variable.id_pool << self.id
    self.schema = Schema.new({ Iter(1) => [Nat.instance],
                               Pos(1) => [Nat.instance] }.merge(
                                 Hash[*items.collect do |it|
                                         [it, [Nat.instance]]
                                       end.flatten_once]) )
  end

  def clone
    Variable.new(id, *items.clone)
  end

  def xml_content
    content do
      variable :name => id
    end
  end

  def ==(other)
    other.class == Variable and
    other.id == self.id
  end

  def set(var,plan)
    if var == self
      plan.clone
    else
      self.clone
    end
  end

  def free
    [ self.clone ]
  end
end

class AggrFun
  include Singleton

  def to_xml
    self.class.to_s.split("::").last.downcase.to_sym
  end

  def clone
    self
  end
end

class Count < AggrFun
end

class Aggr < Unary
  def_node :column, :aggregate

  attr_accessor :item, :part_list, :aggr_kind
  def_sig :aggr_kind=, AggrFun
  def_sig :part_list=, [Attribute]
  def_sig :item=, Attribute

  def initialize(op, aggr_kind, item, part)
    self.item = item
    self.aggr_kind = aggr_kind
    self.part_list = part
    super(op)
  end

  def child=(op)
    unless op.schema.attributes?(part_list)
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{part_list}."
    end
    unless op.schema.attributes?([item])
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{item}."
    end
    self.schema = Schema.new( { self.item => [Nat.instance] }.merge(
                             Hash[*part_list.collect do |p|
                                     [p, op.schema[p]]
                                   end.flatten_once]))
                          
    super(op)
  end

  def xml_content
    content do
      part_list.collect do |part|
        column :name => part.to_xml, :function => :partition, :new => false
      end.join + 
      (aggregate :kind => aggr_kind.to_xml do
        column :name => item.to_xml, :new => true
      end)
    end
  end

  def clone
    Aggr.new(
      child.clone,
      aggr_kind.clone,
      item.clone,
      part_list.clone)
  end

  def set(var,plan)
    Aggr.new(
      child.set(var,plan),
      aggr_kind.clone,
      item.clone,
      part_list.clone)
  end
end

class RelLambda < Binary
  def_node :parametrized_plan
  def initialize(op1, op2)
    super(op1,op2)
  end

  def left_and_right(op1,op2)
    self.schema = Schema.new( { Iter(1) => [Nat.instance],
                                Pos(1) => [Nat.instance],
                                # this is a dummy node
                                Item(1) => [Nat.instance] } )
    super(op1,op2)
  end
  def_sig :left_and_right, Variable, Operator

  def serialize
    xml_id = 0
    self.traverse do |op|
      op.ann_xml_id = xml_id += 1
    end

    xml_list = []

    self.traverse_strategy = Locomotive::AstHelpers::PostOrderTraverse
    self.traverse do |op|
      xml_list << op.to_xml
    end

    parametrized_plan :comment => "not mentioned for execution" do
      xml_list.join
    end
  end

  # performs a beta reduction on the right
  # plan side
  def apply(arg)
    right.set(left, arg)
  end

  def clone
    RelLambda.new(op1.clone,
                  op2.clone)
  end

  def set(var,plan)
    if var == self.left
      right.clone
    else
      if !right.free.member?(var) or
         !plan.free.member?(left)
         RelLambda.new(
           left.clone,
           right.set(var, plan))
      else
         # alpha reduction
         new_var = Variable.new_variable
         RelLambda.new(
           new_var,
           right.set(left,new_var)).set(var,plan)
      end
    end
  end

  def free
    # the variable in the left branch
    # is not a free variable anymore
    right.free - [left]
  end

  def bound
    # the variable in the right branch
    # is now a bound variable
    [left.clone] + right.bound
  end
end

class Nil < Leaf
  def clone
    Nil.new
  end
end

class LiteralList
  include Locomotive::XML
  def_node :column

  protected

  attr_accessor :literal_list
  def_sig :literal_list=, { Attribute => [Atomic] }
  

  public

  def initialize(hash)
    self.literal_list = hash
  end

  def attributes
    literal_list.keys
  end

  def method_missing(mtd, *params, &block)
    if literal_list.respond_to? mtd
      literal_list.send(mtd, *params, &block)
    else
      super.method_missing(mtd, *params, &block)
    end
  end

  def to_xml
    literal_list.collect do |attr,atomary|
      column :name => attr.to_xml, :new => true do 
        atomary.collect do |atom|
          atom.to_xml
        end.join
      end
    end.join
  end

  def clone
    LiteralList.new( literal_list.clone )
  end
end

class LiteralTable < Leaf
  attr_reader :lit_list

  def lit_list=(llist)
    s = Hash[ *llist.collect do |attr, types|
                       [attr,types.collect { |a| a.type }.uniq]
                     end.flatten_once ]
    self.schema = Schema.new(s)
    @lit_list = llist
  end
  def_sig :lit_list=, LiteralList

  def initialize(llist)
    self.lit_list = llist
  end

  def xml_kind
    :table
  end

  def xml_content
    content do
      lit_list.to_xml
    end
  end

  def clone
    LiteralTable.new( lit_list.clone )
  end
end

class RefTbl < Leaf
  def_node :table, :properties, :keys, :key

  private

  def columns
    @columns ||= engine.columns(name,
                                 "#{name} columns")
  end

  def keys
    @keys = columns.select do |col|
              col.primary
            end
  end

  def get_schema
    mapping =
      { :integer => Int.instance,
        :float   => Dec.instance,
        :string  => Str.instance }
    id = 0
    Schema.new(
      Hash[*columns.collect do |col|
              [Item(id += 1), [mapping[col.type]]]
            end.flatten_once])
  end

  def get_name_mapping
    id = 0
    columns.collect do |col|
       [ Item(id += 1), NamedAttribute(col.name) ]
     end.to_hash
  end
  
  public

  cattr_accessor :engine
  attr_reader :engine
  attr_accessor :name
  def_sig :name=, String
  attr_reader :name_mapping

  def initialize(name, engine = nil)
    @engine = engine || Table.engine
    @name = name
    @name_mapping = get_name_mapping
    self.schema = get_schema
  end

  def reset
    @columns = nil
    @keys = nil
  end

  def xml_kind
    :ref_tbl
  end

  def xml_content
    content do
      table :name => name do 
        name_mapping.collect do |new,old|
          column :name => new.to_xml, :tname => old.to_xml, :type => schema[new].first.to_xml
        end.join
      end
    end
  end

  def clone
    RefTbl.new(name.clone, engine)
  end
end

class ProjectList
  include Locomotive::XML
  def_node :column

  private

  attr_accessor :project_list
  def_sig :project_list=, { Attribute => [Attribute] }
  
  public

  def initialize(hash)
    self.project_list = hash
  end

  def old_items
    project_list.keys
  end

  def new_items
    project_list.values.flatten
  end

  def method_missing(mtd, *params, &block)
    if project_list.respond_to? mtd
      project_list.send(mtd, *params, &block)
    else
      super.method_missing(mtd, *params, &block)
    end
  end

  def to_xml
    project_list.collect do |old,news|
      news.collect do |new|
        column :name => new.to_xml,
               :old_name => old.to_xml,
               :new => new != old
      end.join
    end.join
  end

  def clone
    ProjectList.new( project_list.clone )
  end
end

class Project < Unary
  private

  attr_accessor :proj_list
  def_sig :proj_list=, ProjectList

  public

  def initialize(op, proj_list)
    self.proj_list = proj_list
    super(op)
  end

  def child=(op)
    unless op.schema.attributes?(proj_list.old_items)
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{proj_list.old_items}."
    end
    proj_list.old_items.each do |old|
      proj_list[old].each do |new|
        schema[new] = op.schema[old]
      end
    end
    super(op)
  end

  def xml_content
    content do
      proj_list.to_xml
    end
  end

  def clone
    Project.new(child.clone, proj_list.clone)
  end

  def set(var,plan)
    Project.new(
      child.set(var,plan),
      proj_list.clone)
  end
end

class Select < Unary
  attr_accessor :item

  def initialize(op,  item)
    self.item = item
    super(op)
  end

  def child=(op)
    unless op.schema.attributes?([item])
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{item}."
    end
    
    pp item
    pp op.schema[item]

    unless op.schema[item].member? Bool.instance
      raise CorruptedSchema,
            "#{item}(#{op.schema[item]}) doesn have the type Boolean."
    end

    self.schema = op.schema.clone
    super(op)
  end

  def xml_content
    content do
      column :name => item.to_xml, :new => false
    end
  end

  def clone
    Select.new(
      self.child.clone,
      self.item.clone)
  end

  def set(var,plan)
    Select.new(
      child.set(var,plan),
      item.clone)
  end
end

class AttachItem
  include Locomotive::XML
  def_node :column

  attr_accessor :attribute
  def_sig :attribute=, Attribute
  attr_accessor :atom
  def_sig :atom=, Atomic

  def initialize(attr, atom)
    self.attribute,
    self.atom = attr, atom
  end

  def to_xml
    column :name => attribute.to_xml,
           :new => true do
      atom.to_xml
    end 
  end

  def clone
    AttachItem.new(attribute, atom)
  end
end

class BinOp < Unary
  attr_accessor :res, :item1, :item2
  def_sig :res=, Attribute
  def_sig :item1=, Attribute
  def_sig :item2=, Attribute

  def initialize(op, res, item1, item2)
    self.res,
    self.item1,
    self.item2 = res, item1, item2
    super(op)
  end

  def child=(op)
    unless op.schema.attributes?([item1])
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{item1}."
    end
    unless op.schema.attributes?([item2])
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{item2}."
    end

    self.schema = op.schema +
             Schema.new({ res => [Bool.instance] })

    super(op)
  end

  def xml_content
    content do
      [column(:name => res.to_xml, :new => true),
       column(:name => item1.to_xml, :new => false, :position => 1),
       column(:name => item2.to_xml, :new => false, :position => 2)].join
    end
  end

  def xml_kind
    self.class.to_s.split('::').last.downcase.to_sym
  end

  def clone
    self.class.new(child.clone,
                   res.clone,
                   item1.clone,
                   item2.clone)
  end

  def set(var, plan)
    self.class.new(
      child.set(var,plan),
      res.clone,
      item1.clone,
      item2.clone)
  end
end

class Or < BinOp; end
class And < BinOp; end

class Attach < Unary
  attr_accessor :item
  def_sig :item=, AttachItem

  def initialize(op, item)
    self.item = item
    super(op)
  end

  def child=(op)
    self.schema = op.schema +
             Schema.new({ item.attribute => [item.atom.type] })
    super(op)
  end

  def xml_content
    content do
      item.to_xml
    end
  end

  def clone
    Attach.new(child.clone, item.clone)
  end

  def set(var, plan)
    Attach.new(
      child.set(var,plan),
      item.clone)
  end
end

class SortDirection
  include Singleton

  def to_xml
    self.class.to_s.split('::').last.downcase.to_sym
  end

  def clone
    # singleton
    self
  end
end

class Ascending < SortDirection; end

class Descending < SortDirection; end

class SortList
  include Locomotive::XML
  def_node :column

  private

  attr_accessor :sort_list
  def_sig :sort_list=, { Attribute => SortDirection }
  
  public

  def initialize(hash)
    self.sort_list = hash
  end

  def attributes
    sort_list.keys
  end

  def method_missing(mtd, *params, &block)
    if sort_list.respond_to? mtd
      sort_list.send(mtd, *params, &block)
    else
      super.method_missing(mtd, *params, &block)
    end
  end

  def to_xml
    pos = -1
    sort_list.collect do |attr, dir|
      column :name => attr.to_xml,
             :function => :sort,
             :position => pos += 1,
             :direction => dir.to_xml,
             :new => false
    end.join
  end

  def clone
     SortList.new( sort_list.clone )
  end
end


class Numbering < Unary
  attr_accessor :res,
                :sort_by
  def_sig :res=, Attribute
  def_sig :sort_by=, SortList

  def initialize(op, res, sortby)
    self.res,
    self.sort_by = res, sortby || SortList.new({}) 
    super(op)
  end

  def child=(op)
    unless op.schema.attributes?(self.sort_by.attributes)
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{sort_by.attributes}."
    end
    self.schema = op.schema + Schema.new({ res => [Nat.instance] })
    super(op)
  end

  def xml_content
    content do
      [column( :name => res.to_xml, :new => true),
       sort_by.to_xml].join
    end
  end

  def clone
    self.class.new(child.clone,
                   res.clone,
                   sort_by.clone)
  end

  def set(var, plan)
    self.class.new(
      child.set(var,plan),
      res.clone,
      sort_by.clone)
  end
end

class RowNum < Numbering
  def_node :column
  
  attr_accessor :part
  def_sig :part=, [Attribute]

  def initialize(op, res, part, sortby)
    self.part = part
    super(op,res,sortby)
  end

  def child=(op)
    unless op.schema.attributes?(part)
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{part}."
    end
    super(op)
  end

  def xml_content
    pos = -1
    content do
      [column(:name => res.to_xml, :new => true),
       sort_by.to_xml,
       part.collect do |p|
         column :name => p.to_xml,
                :function => :part,
                :position => pos += 1,
                :new => false
       end.join].join
    end
  end

  def clone
    RowNum.new(child.clone,
               res.clone,
               part.clone,
               sort_by.clone)
  end

  def set(var,plan)
    RowNum.new(
      child.set(var,plan),
      res.clone, part.clone, sort_by.clone)
  end
end

class RowRank < Numbering
end

class Rank < Numbering
end

class RowId < Numbering
  def initialize(op, res)
    super(op,res,nil)
  end

  def clone
    RowId.new(child.clone,
                res.clone)
  end

  def set(var,plan)
    RowId.new(
      child.set(var,plan),
      res.clone)
  end
end

class Fun
  include Singleton

  def to_xml
    self.class.to_s.split("::").last.downcase
  end

  def clone
    #singleton
    self
  end
end
class Addition < Fun
  def to_xml
    :add
  end
end
class Subtraction < Fun
  def to_xml
    :subtract
  end
end
class Multiplication < Fun
  def to_xml
    :multiply
  end
end
class Division < Fun
  def to_xml
    :divide
  end
end
class Contains < Fun
  def to_xml
    :contains
  end
end

class Function < Unary;
  def_node :column, :kind

  attr_accessor :res,
                :operator,
                :items
  def_sig :res=, Attribute
  def_sig :operator=, Fun
  def_sig :items=, [Attribute]

 
  def initialize(op, operator, res, items)
    self.operator,
    self.res,
    self.items = operator, res, items
    super(op)
  end

  def child=(op)
    unless op.schema.attributes?(self.items)
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{items}."
    end

    self.schema = op.schema +
                    Schema.new( { res => op.schema[items.first] } )
    super(op)
  end

  def xml_kind
    :fun
  end

  def xml_content
    content do
      [
       kind(:name => operator.to_xml),
       column(:name => res.to_xml, :new => true),
       items.collect do |it|
         column :name => it.to_xml, :new => false
       end.join
      ].join
    end
  end

  def clone
    Function.new(child.clone,
                 operator.clone,
                 res.clone,
                 items.clone)
  end

  def set(var, plan)
    Function.new(
      child.set(var,plan),
      operator.clone,
      res.clone,
      items.clone) 
  end
end

class Join < Binary; end
class Set < Binary
  def left_and_right(op1,op2)
    self.schema = op1.schema.clone
    super(op1,op2)
  end

  def clone
    self.class.new(left.clone, right.clone)
  end

  def set(var,plan)
    self.class.new(
      left.set(var,plan),
      right.set(var,plan))
  end
end

class Comparison < Unary
  def_node 
  attr_accessor :res,
                :item1,
                :item2
  def_sig :res=, Attribute
  def_sig :item1=, Attribute
  def_sig :item2=, Attribute

  def initialize(op, res, item1, item2)
    self.res,
    self.item1,
    self.item2 = res, item1, item2
    super(op)
  end

  def child=(op)
    unless op.schema.attributes?([self.item1])
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{item1}."
    end
    unless op.schema.attributes?([self.item2])
      raise CorruptedSchema,
            "Schema #{op.schema.attributes} does not " \
            "contain all attributes of #{item2}."
    end

    self.schema = op.schema + Schema.new({ self.res => [Bool.instance]})
    super(op)
  end

  def clone
    self.class.new(child.clone,
                   res.clone,
                   item1.clone,
                   item2.clone)
  end

  def set(var,plan)
    self.class.new(
      child.set(var,plan),
      res.clone,
      item1.clone,
      item2.clone)
  end

  def xml_content
        content do
      [column(:name => res.to_xml, :new => true),
       column(:name => item1.to_xml, :new => false, :position => 1),
       column(:name => item2.to_xml, :new => false, :position => 2)
      ].join
    end

  end
end

class Serialize < Binary; end

# join operators
class Cross < Join
  def initialize(op1,op2)
    super(op1,op2)
  end

  def left_and_right(op1,op2)
    self.schema = op1.schema + op2.schema
    super(op1,op2)
  end

  def clone
    Cross.new(left.clone,right.clone)
  end

  def set(var,plan)
    Cross.new(
      left.set(var,plan),
      right.set(var,plan))
  end
end

class Eqjoin < Join
  attr_accessor :item1
  def_sig :item1=, Attribute
  attr_accessor :item2
  def_sig :item2=, Attribute


  def initialize(op1,op2,it1,it2)
    self.item1,
    self.item2 = it1, it2
    super(op1,op2)
  end

  def left_and_right(op1,op2)
    unless op1.schema.attributes?([self.item1])
      raise CorruptedSchema,
            "Schema #{op1.schema.attributes} does not " \
            "contain all attributes of #{item1}."
    end
    unless op2.schema.attributes?([self.item2])
      raise CorruptedSchema,
            "Schema #{op2.schema.attributes} does not " \
            "contain all attributes of #{item2}."
    end
    self.schema = op1.schema + op2.schema
    super(op1,op2)
  end

  def xml_content
    content do
      [column(:name => item1.to_xml, :new => false, :position => 1),
       column(:name => item2.to_xml, :new => false, :position => 2)
      ].join
    end
  end

  def clone
    Eqjoin.new(left.clone,right.clone,
               item1.clone, item2.clone)
  end

  def set(var,plan)
    Eqjoin.new(
      left.set(var,plan),
      right.set(var,plan),
      item1.clone,
      item2.clone)
  end
end

class Predicate
  include Locomotive::XML
  def_node :column, :comparison

  private

  def first=(first)
    @first = first
  end
  def_sig :first=, Attribute

  def second=(snd)
    @second = snd
  end
  def_sig :second=, Attribute

  public

  attr_reader :first,
              :second

  def initialize(first_, second_)
    self.first,
    self.second = first_, second_
  end

  def clone
    self.class.new(first.clone,second.clone)
  end
end


class Equivalence < Predicate
  def to_xml
    comparison :kind => :eq do
      [column(:name => first.to_xml, :new => false, :position => 1),
       column(:name => second.to_xml, :new => false, :position => 2)].join
    end
  end
end


class PredicateList
  include Locomotive::XML
  def_node :content

  private

  attr_accessor :pred_list
  def_sig :pred_list=, [Predicate]

  public

  def initialize(*ary)
    self.pred_list = ary
  end

  def method_missing(mtd, *params, &block)
    if pred_list.respond_to? mtd
      pred_list.send(mtd, *params, &block)
    else
      super.method_missing(mtd, *params, &block)
    end
  end

  def to_xml
    pred_list.collect do |pred|
      pred.to_xml
    end.join
  end

  def clone
    PredicateList.new( *pred_list.clone )
  end
end

class ThetaJoin < Join
  attr_accessor :predicate_list
  def_sig :predicate_list=, PredicateList

  def initialize(op1, op2, pred_list)
    self.predicate_list = pred_list
    super(op1,op2)
  end

  def left_and_right(op1,op2)
    self.schema = op1.schema + op2.schema
    super(op1,op2)
  end

  def xml_content
    content do
      predicate_list.to_xml
    end
  end

  def clone
    ThetaJoin.new(left.clone,
                  right.clone,
                  predicate_list.clone)
  end

  def set(var,plan)
    ThetaJoin.new(
      left.set(var,plan),
      right.set(var,plan))
  end
end

# set operators 
# FIXME: sanity checks (schemas have to be equal)
class Union < Set; end
class Difference < Set; end

# comparison operators
class Equal < Comparison;
  def xml_kind
    :eq
  end
end
class LessThen < Comparison
  def xml_kind
    :lt
  end
end
class GreaterThen < Comparison
  def xml_kind
    :gt
  end
end
class LessEqualThen < Comparison
  def xml_kind
    :lteq
  end
end
class GreaterEqualThen < Comparison
  def xml_kind
    :gteq
  end
end

# serialize operator
class SerializeRelation < Serialize
  include Locomotive::XML
  def_node :logical_query_plan

  attr_accessor :iter,
                :pos,
                :items
  def_sig :iter=, Attribute
  def_sig :pos=, Attribute
  def_sig :items=, [Attribute]

  def initialize(side,alg,iter,pos,items)
    self.iter,
    self.pos,
    self.items = iter, pos, items
    super(side,alg)
  end

  def left_and_right(side,alg)
    unless alg.schema.attributes?([self.iter])
      raise CorruptedSchema,
            "Schema #{alg.schema.attributes} does not " \
            "contain all attributes of #{iter}."
    end
    unless alg.schema.attributes?([self.pos])
      raise CorruptedSchema,
            "Schema #{alg.schema.attributes} does not " \
            "contain all attributes of #{pos}."
    end
    unless alg.schema.attributes?(self.items)
      raise CorruptedSchema,
            "Schema #{alg.schema.attributes} does not " \
            "contain all attributes of #{items}."
    end
    self.schema = alg.schema.clone
    super(side,alg)
  end

  def xml_kind
    "serialize relation".to_sym
  end

  def xml_content
    pos_ = -1
    content do
      [
        column(:name => iter.to_xml, :new => false, :function => :iter),
        column(:name => pos.to_xml, :new => false, :function => :pos),
        items.collect do |it|
          column :name => it.to_xml,
                 :new => false,
                 :function => :item,
                 :position => pos_ += 1
        end.join
      ].join
    end
  end

  def serialize
    xml_id = 0
    self.traverse do |op|
      op.ann_xml_id = xml_id += 1
    end

    xml_list = []

    self.traverse_strategy = Locomotive::AstHelpers::PostOrderTraverse
    self.traverse do |op|
      xml_list << op.to_xml
    end

    logical_query_plan :unique_names => true do
      xml_list.join
    end
  end

  def clone
    Serialization.new(left.clone,
                      right.clone,
                      iter.clone,
                      pos.clone,
                      items.clone)
  end

  def set(var,plan)
    Serialization.new(
      left.set(var,plan),
      right.set(var,plan),
      iter.clone,
      pos.clone,
      items.clone)
  end
end

class PayloadList
  private

  attr_accessor :attributes
  def_sig :attributes=, [Attribute]

  public

  def initialize(ary)
    self.attributes = ary
  end

  def method_missing(mtd, *params, &block)
    if attributes.respond_to? mtd
      attributes.send(mtd, *params, &block)
    else
      super.method_missing(mtd, *params, &block)
    end 
  end

  def clone
    PayloadList.new( attributes.clone )
  end
end

# Forward declaration 
class QueryInformationNode; end

class SurrogateList
  protected

  attr_accessor :surrogates
  def_sig :surrogates=, { Attributes => QueryInformationNode }

  public

  def initialize(hash)
    self.surrogates = hash   
  end

  def +(sur)
    SurrogateList.new(surrogates.merge(sur.surrogates))
  end

  def itapp(q_0, itbl_2)
    if self.keys != itbl_2.keys
      raise ITblsNotEqual,
            "#{self.keys} != #{itbl_2.keys}"
    end

    if self.empty? and itbl_2.empty?
      return SurrogateList.new( {} )
    end

    c = self.first.first

    q1_in = self[c]
    q2_in = itbl_2[c]
  
    # (1)
    q = RowId.new(
          Union.new(
            Attach.new(
              q1_in.plan,
              AttachItem.new(Iter(2),Atomic.new(2, Nat.instance))),
            Attach.new(
              q2_in.plan,
              AttachItem.new(Iter(2),Atomic.new(1, Nat.instance)))),
          Item(2))
    #(2)
    c_new = c.class.new(c.id + 100)
    q_prime = Project.new(
                ThetaJoin.new(
                  q,
                  Project.new(
                    q_0,
                    ProjectList.new( { Iter(2) => [ Iter(3) ],
                                       Item(2) => [ Item(3) ],
                                       c       => [ c_new ] })),
                  PredicateList.new( Equivalence.new(Iter(2), Iter(3)),
                                     Equivalence.new(Iter(1), c_new) )),
                ProjectList.new( { Item(3) => [ Iter(1) ],
                                   Pos(1)  => [ Pos(1) ] }.merge(
                                     { Item(2) => q1_in.surrogates.keys }).merge(
                                     Hash[*(q1_in.payload_items - q1_in.surrogates.keys).collect do |col|
                                              [col, [col]]
                                            end.flatten_once])))
     # (3)          
     itbl_prime = q1_in.surrogates.itapp(q, q2_in.surrogates)
     # (4)
     itbl_2prime = SurrogateList.new(
                     self.delete_if { |k,v| k == c}).itapp(q_0,
                                           SurrogateList.new(itbl_2.delete_if { |k,v| k == c}))
     # (5)
     SurrogateList.new( { c => QueryInformationNode.new(
                                 q_prime, q1_in.payload_items, itbl_prime) } ) + itbl_2prime
  end
  def_sig :itapp, Operator, SurrogateList

  def method_missing(mtd, *params, &block)
    if surrogates.respond_to? mtd
      surrogates.send(mtd, *params, &block)
    else
      super(mtd, *params, &block) 
    end
  end

  def clone
    SurrogateList.new( surrogates.clone )
  end
end

class QueryInformationNode
  attr_accessor :plan,
                :payload_items,
                :surrogates,
                :methods

  def_sig :plan=, Operator
  def_sig :payload_items=, PayloadList
  def_sig :surrogates=, SurrogateList
  def_sig :methods=, { Symbol => RelLambda }

  def initialize(plan, payloads, surrogates, methods={})
    self.plan,
    self.payload_items,
    self.surrogates = plan, payloads, surrogates
    self.methods = methods
  end

  def clone
    QueryInformationNode.new(plan.clone,
                             payload_items.clone,
                             surrogates.clone)
  end
end

class ResultType
  include Singleton
  def to_xml
    self.class.to_s.split("::").last.upcase
  end

  def clone
    # singleton
    self
  end
end
class Tuple < ResultType; end 

class QueryPlanBundle
  include Locomotive::XML
  def_node :query_plan_bundle,
           :query_plan,
           :properties, :property

  XML_Prolog = '<?xml version="1.0" encoding="UTF-8"?>'+"\n"

  attr_accessor :logical_query_plans
  def_sig :logical_query_plans=, [Operator]

  def initialize(lplans)
    self.logical_query_plans = lplans
  end

  def to_xml
    qid = -1
    XML_Prolog +
    query_plan_bundle do
      logical_query_plans.collect do |lplan|
        query_plan :id => qid += 1, :idref => qid - 1, :colref => 1 do
          [properties do
             property(:name => :overallResultType, :value => :LIST)
           end,
           lplan.serialize].join
        end
      end.join
    end
  end

  def clone
    QueryPlanBundle.new( logical_query_plans.clone )
  end
end

end

end

end

