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
  extend Locomotive::TypeChecking::Signature
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
end

# represents a variant operator of the
# relational algebra
class Operator < RelAlgAstNode
  extend Locomotive::TypeChecking::Signature
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

class Nil < Leaf; end
class LiteralList
  extend Locomotive::TypeChecking::Signature
  include Locomotive::XML
  def_node :column

  private

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
end

class RefTbl < Leaf
  def_node :table

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
    Hash[*columns.collect do |col|
            [ Item(id += 1), NamedAttribute(col.name) ]
          end.flatten]
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
end

class ProjectList
  extend Locomotive::TypeChecking::Signature
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
end

class AttachItem
  extend Locomotive::TypeChecking::Signature
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
end

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
end

class SortDirection
  include Singleton
  include Locomotive::XML
end

class Ascending < SortDirection
end

class Descending < SortDirection
end

class SortList
  extend Locomotive::TypeChecking::Signature
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
end


class Numbering < Unary
  attr_accessor :res,
                :sort_by
  def_sig :res=, Attribute
  def_sig :sort_by=, SortList

  def initialize(op, res, sortby)
    self.res,
    self.sort_by = res, sortby || {} 
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
         column :name => p,
                :function => :part,
                :position => pos += 1,
                :new => false
       end.join].join
    end
  end
end

class RowRank < Numbering
end

class Rank < Numbering
end

class RowId < Numbering
end

class Fun
  include Singleton

  def to_xml
    self.class.to_s.split("::").last.downcase
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
end

class Join < Binary; end
class Set < Binary
  def left_and_right(op1,op2)
    self.schema = op1.schema.clone
    super(op1,op2)
  end
end

class Comparison < Unary
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
end

class PredicateOp
  include Singleton
end

class Equivalence < PredicateOp
  def to_xml
    :eq
  end
end



class Predicate
  extend Locomotive::TypeChecking::Signature
  include Locomotive::XML
  def_node :column, :comparison

  private

  def op=(op)
    @op = op
  end
  def_sig :op=, PredicateOp

  def first=(first)
    @first = first
  end
  def_sig :first=, Attribute

  def second=(snd)
    @second = snd
  end
  def_sig :second=, Attribute

  public

  attr_reader :op,
              :first,
              :second

  def initialize(op_, first_, second_)
    self.op,
    self.first,
    self.second = op_, first_, second_
  end

  def to_xml
    comparison :kind => op.to_xml do
      [column(:name => first.to_xml, :new => false, :position => 1),
       column(:name => second.to_xml, :new => false, :position => 2)].join
    end
  end
end

class PredicateList
  extend Locomotive::TypeChecking::Signature
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
end

class ThetaJoin < Join
  extend Locomotive::TypeChecking::Signature

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
end

# set operators 
class Union < Set
  def left_and_right(op1,op2)
    if op1.schema.attributes.to_a != op2.schema.attributes.to_a
      raise CorruptedSchema,
            "#{op1.schema.attributes.to_a} != #{op2.schema.attributes.to_a}"
    end
    super(op1,op2)
  end
end
class Difference < Set; end

# comparison operators
class Equal < Comparison; end
class LessThen < Comparison; end
class GreaterThen < Comparison; end
class LessEqualThen < Comparison; end
class GreaterEqualThen < Comparison; end

# serialize operator
class SerializeRelation < Serialize
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
end

class PayloadList
  extend Locomotive::TypeChecking::Signature

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

end

# Forward declaration 
class QueryInformationNode; end

class SurrogateList
  extend Locomotive::TypeChecking::Signature

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
          Item(2),
          SortList.new( { Iter(1) => Ascending.instance,
                          Iter(2) => Ascending.instance,
                          Pos(1)  => Ascending.instance } ))
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
                  PredicateList.new( Predicate.new(Equivalence.instance, Iter(2), Iter(3)),
                                     Predicate.new(Equivalence.instance, Iter(1), c_new) )),
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
end

class QueryInformationNode
  extend Locomotive::TypeChecking::Signature
  attr_accessor :plan,
                :payload_items,
                :surrogates

  def_sig :plan=, Operator
  def_sig :payload_items=, PayloadList
  def_sig :surrogates=, SurrogateList

  def initialize(plan, payloads, surrogates)
    self.plan,
    self.payload_items,
    self.surrogates = plan, payloads, surrogates
  end
end

class ResultType
  def to_xml
    self.class.to_s.split("::").last.upcase
  end
end
class Tuple < ResultType; end 

class QueryPlanBundle
  extend Locomotive::TypeChecking::Signature
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
end

end

end

end
