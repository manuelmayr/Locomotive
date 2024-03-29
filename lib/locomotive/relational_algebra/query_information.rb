module Locomotive

  module RelationalAlgebra 
    # Forward declaration 
    class QueryInformationNode; end
    
    class SurrogateList
      public
      delegate :[],
               :to_a,
               :each,
               :keys,
               :empty?,
               :first,
               :size,
               :to => :surrogates

      attr_accessor :surrogates
      def_sig :surrogates=, { ConstAttribute => QueryInformationNode }
    
      def initialize(hash)
        self.surrogates = hash   
      end

      def map(&block)
        SurrogateList.new(
          surrogates.map(&block).to_hash)
      end
    
      def +(sur)
        SurrogateList.new(surrogates.merge(sur.surrogates))
      end

      def delete_if(&lambda)
        SurrogateList.new(self.clone.surrogates.delete_if(&lambda))
      end
    
      def itapp(q_0, *itbls)
        if itbls.any? { |i| self.keys != i.keys }
          raise ITblsNotEqual,
                "some itbls keys are not equal"
        end
    
        if self.empty? and 
           itbls.all? { |i| i.empty? }
          return SurrogateList.new( {} )
        end
    
        c = self.first.first
    
        q1_in = self[c]
        qs_in = itbls.map { |itbl| itbl[c] }

        q1 = q1_in.plan
        qs = qs_in.map { |q| q.plan }
        cols_q1, itbls_q1 = q1_in.column_structure, q1_in.surrogates
        ord, ord_, item_, item__ = Iter.new(2), Iter.new(4),
                                       Iter.new(3), Item.new(3)
      
        # (1)
        q1_ = q1.attach(AttachItem.new(ord, RAtomic.new(1, RNat.type)))
        q = qs.zip(2..qs.size+1).reduce(q1_) do |p1,p2|
              p1.union(
                 p2.first.attach(AttachItem.new(ord, RAtomic.new(p2.last, RNat.type))))
            end.row_num(item_, [], [Iter.new(1), ord, Pos.new(1)])
        
        #(2)
        c_new = Iter.new(5)
        q_ = q_0.project( ord => [ord_],
                          item_ => [item__],
                          c     => [c_new] ).
                 theta_join(q, [Equivalence.new(ord_, ord),
                                Equivalence.new(c_new, Iter.new(1))] ).
                 project( { item__ => [Iter.new(1)],
                            Pos.new(1) => [Pos.new(1)],
                            item_ => itbls_q1.keys  }.
                            merge(
                              (cols_q1 - itbls_q1.keys).items.collect do |col|
                                [col, [col]]
                              end.to_hash) )

         # (3)          
         itbl_ = q1_in.surrogates.itapp(q, *qs_in.map { |q| q.surrogates })
         # (4)
         itbl__ = self.delete_if { |k,v| k == c}.
                    itapp(q_0, *itbls.map { |i| i.delete_if { |k,v| k == c} })
         # (5)
         SurrogateList.new( { c => QueryInformationNode.new(
                                     q_, cols_q1, itbl_) } ) + itbl__
      end

      def itsel(q_0)
        return SurrogateList.new({}) if self.empty? 

        c = self.first.first
        cols, itbls, q = self[c].column_structure, self[c].surrogates, self[c].plan
        c_ = (self.keys + cols.items).max.inc

        # (1)
        q_ = q.equi_join(q_0.project( c => [c_]), Iter.new(1), c_).
               project( [Iter.new(1), Pos.new(1)] + cols.items )

        itbls_ = itbls.itsel(q_)
        itbls__ = self.delete_if { |k,v| k == c }.itsel(q_0)

        SurrogateList.new(
          { c => QueryInformationNode.new(q_, cols, itbls_) }.
          merge( itbls__.to_a.to_hash ) )
      end

      def join
        itbls = surrogates.to_a

        itbls.rest.reduce(itbls.first.last) do |qi,surr|
          # the query_information node
          qin_j = surr.last
           
          cols_j  = surr.last.column_structure
          itbls_j = surr.last.surrogates
          cols_c  = qi.column_structure
          itbls_c = qi.surrogates

          # adapt cols
          cols_j_ = cols_j.clone
          cols_j_.items.each { |i| i.inc!(qi.column_structure.count) }
          # adapt itbls
          itbls_j_ = itbls_j.map { |k,q| [k.inc(qi.column_structure.count), q] }

          # calculate new plan
          q_j = qin_j.plan.project({ Iter.new(1) => [Iter.new(2)],
                                     Pos.new(1)  => [Pos.new(2)] }.
                                    merge(
                                      cols_j.items.zip(cols_j_.items).
                                        map do |old,new|
                                          [old,[new]]
                                        end.to_hash))

          q_ = q_j.theta_join(qi.plan, [Equivalence.new(Iter.new(2), Iter.new(1)),
                                                Equivalence.new(Pos.new(2), Pos.new(1))]).
                           project([Iter.new(1), Pos.new(1)] + cols_c.items + cols_j_.items)


          QueryInformationNode.new(q_, cols_c + cols_j_, itbls_c + itbls_j_)
        end
      end

      def set(var, plan)
        self.map do |item, itbl|
          [item,QueryInformationNode.new(itbl.plan.set(var, plan), 
                                         itbl.column_structure,
                                         itbl.surrogates.set(var,plan))]
        end
      end
    
      def clone
        # only clone the attributes since we don't modify
        # the plan
        SurrogateList.new( surrogates.map { |k,v| [k.clone,v] }.to_hash )
      end

      def filter_and_adapt(items)
        item_min = items.min
        # we are modifying the structure itself
        # so we have to clone it (sideeffect)
        surr_new = self.delete_if do |it, itbl|
          !items.member?(it)
        end
       # adapt the keys
       surr_new.map { |k,p| [Item.new(k.id - (item_min.id - 1)), p] }
     end
    end

    class ColumnStructureEntry
    end

    class OffsetType < ColumnStructureEntry
      private
        include Locomotive::XML
        def_node :offset_

      public
      attr_reader :offset,
                  :type

      def initialize(offset, type)
        @offset = offset
        @type   = type
      end

      def items
        [offset]
      end

      def offsets
        [self]
      end

      def clone
        OffsetType.new(offset.clone,
                       type.clone)
      end

      def to_xml
        offset_ :item => offset.to_xml, :type => type.to_xml
      end
    end

    class AttributeColumnStructure < ColumnStructureEntry
      private
        include Locomotive::XML
        def_node :attribute_

      public
      attr_reader :attribute,
                  :column_structure

      def initialize(attribute, cs)
        @attribute = attribute
        @column_structure = cs
      end

      def items
        column_structure.items.flatten
      end

      def offsets
        column_structure.offsets.flatten
      end

      def clone
        AttributeColumnStructure.new(attribute.clone,
                                     column_structure.clone)
      end

      def to_xml
        attribute_ :name => attribute.to_xml do
          column_structure.to_xml
        end
      end
    end

    class ColumnStructure
      private
        include Locomotive::XML
        def_node :column_structure

        def to_cs_entry(entry)
          return entry if OffsetType === entry or
                          AttributeColumnStructure === entry

          if !(Array === entry and entry.size == 2) then
            raise ArgumentError,
                  "entry is not a column_structure_entry"
          end

          case
            when Item === entry.first,
                 RType === entry.last then
               OffsetType.new(entry.first, entry.last)
            when Attribute === entry.first then
               if Array === entry.last then
                 AttributeColumnStructure.new(entry.first,
                     ColumnStructure.new(entry.last))
               elsif ColumnStructure === entry.last then
                 AttributeColumnStructure.new(entry.first,
                     entry.last)
               end
            else
              raise ArgumentError,
                    "entry is not a column_structure_entry"
          end
        end

        def search_by_attribute(attribute)
          entries.select do |entry|
            entry.attribute == attribute
          end.first
        end

        def search_by_item(offset)
          entries.select do |entry|
            entry.offset == offset
          end.first
        end

      public
        attr_reader :entries

        delegate :first,
                 :map,
                 :collect,
                 :count,
                 :zip,
                 :to => :entries

        def initialize(entries)
          @entries = entries.map do |entry|
                       to_cs_entry(entry)
                     end
        end

        def add(entries)
          entries_ = entries

          if ColumnStructure === entries then
            entries_ = entries.entries
          end

          ColumnStructure.new(self.entries +
            entries_.map { |e| to_cs_entry(e) })
        end
        alias :+ :add

        def [](attribute_index)
          # just look on the surface if you find the right attribute
          case attribute_index
            when Fixnum then
              entries[attribute_index]
            when Symbol then 
              # creating an attribute to be consistent in the signature
              attribute = Attribute.new(attribute_index)
              attr = search_by_attribute(attribute).
              attr.nil? ? nil : attr.column_structure
            when Attribute then
              attr = search_by_attribute(attribute_index)
              attr.nil? ? nil : attr.column_structure
            when Item then
              attr = search_by_attribute(attribute_index)
              attr.nil? ? nil : ColumnStructure.new([search_by_item(attribute_index)])
            else 
              raise ArgumentError, 
                    "Argument should be a (Fixnum | Symbol | Attribute | Item)"
          end
        end

        def -(array)
          ColumnStructure.new(
            entries.clone.delete_if do |entry|
              case
                when AttributeColumnStructure === entry then
                  array.any? { |a| entry.items.member? a }
                when OffsetType === entry
                  array.member? entry.offset
                else
                  raise StandardError, "Not a cs-entry"
              end
            end)
        end

        def clone
          ColumnStructure.new(
            entries.map { |e| e.clone })
        end

        def items
          entries.map do |entry|
            entry.items
          end.flatten
        end

        def offsets
          entries.map do |entry|
            entry.offsets
          end.flatten
        end

        def adapt
          item_min =  self.items.min
          # we are modifying the structure
          # itself (sideeffect) so we have to
          # do a clone of it
          cs_new = self.clone
          cs_new.items.each do |it|
            it.dec!(item_min.id - 1)
          end
          cs_new
        end

        def to_xml
          column_structure do
            entries.collect do |e|
              e.to_xml
            end.join
          end
        end
    end
    
    class SideEffects
      private 

      def to_side_effect(side)
        case
          when Array === side then 
            side
          when SideEffects === side then 
            side.side
          when Operator === side then
            [side]
        end
      end

      public 

      attr_reader :side

      def initialize(side)
        @side = to_side_effect side
      end

      def add(side_effect)
        SideEffects.new(
          @side + to_side_effect(side_effect))
      end
      alias :+ :add


      def plan
        @side.reduce(Nil.new) do |s1, s2|
          s1.error(s2, Item.new(1))
        end
      end
    end
 
    class QueryInformationNode
      private 

      def to_cs_structure(cs_structure)
        case
          when Array === cs_structure then
            ColumnStructure.new(cs_structure)
          when ColumnStructure === cs_structure then
            cs_structure 
          else raise ArgumentError,
                     "#{cs_structure.class} is not a column_structure"
        end
      end

      def to_surrogates(surrogates)
        case
          when NilClass === surrogates then
            SurrogateList.new({})
          when Hash === surrogates then
            SurrogateList.new(surrogates)
          when SurrogateList === surrogates then
            surrogates
          else raise ArgumentError,
                     "surrogates doesn't seem to be a surrogate_list"
        end
      end

      def to_side_effects(side_effects)
        case
          when NilClass === side_effects then
            SideEffects.new([])
          when Array === side_effects then
            SideEffects.new(side_effects)
          when SideEffects === side_effects then
            side_effects
          else raise ArgumentError,
                     "side_effects doesn't seem to be a side_effect"
        end
      end

      public
      attr_accessor :plan,
                    :column_structure,
                    :surrogates,
                    :side_effects,
                    :methods
    
      def_sig :plan=, Operator
      def_sig :column_structure=, ColumnStructure
      def_sig :surrogates=, SurrogateList
      def_sig :side_effects=, SideEffects
      def_sig :methods=, { Symbol => RelLambda }
    
      def initialize(plan, cs_structure, surrogates=nil, side_effects=nil, methods={})
        self.plan,
        self.column_structure,
        self.surrogates,
        self.side_effects = plan, to_cs_structure(cs_structure),
                            to_surrogates(surrogates),
                            to_side_effects(side_effects)
        
        unless self.plan.schema.attributes?(self.column_structure.items) then 
          raise StandardError, "Queryplan doesn't contain all attributes of" \
                               " #{self.column_structure.items.inspect}"
        end
        self.methods = methods
      end

      def frag 
        itbls_hash = {}

        column_structure.
          zip(1..column_structure.count).each do |c, i|

          cols_c = column_structure[i-1].column_structure.adapt
          itbls_c = surrogates.filter_and_adapt(c.items)

          q_c = plan.project({ Iter.new(1) => [Iter.new(1)],
                               Pos.new(1)  => [Pos.new(1)] }.
                             merge(
                               c.items.zip(cols_c.items).
                                 map do |old,new|
                                   [old,[new]]
                               end.to_hash))
        
          itbls_hash = itbls_hash.merge(
                          { Item.new(i) => QueryInformationNode.new(
                                             q_c,
                                             cols_c,
                                             itbls_c) })
        end

        SurrogateList.new( itbls_hash )
      end
    
      def clone
        QueryInformationNode.new(plan,
                                 column_structure.clone,
                                 surrogates.clone)
      end
    end
    
    class ResultType
      include Singleton

      class << self
        alias :type :instance
      end

      def to_xml
        self.class.to_s.split("::").last.upcase
      end
    
      def clone
        # singleton
        self
      end
    end

    class List < ResultType; end
    class Atom < ResultType; end

    class QueryPlan
      private 
      
      include Locomotive::XML
      def_node :query_plan,
               :properties, :property

      public

      attr_reader :id,
                  :idref,
                  :colref,
                  :plan,
                  :cols,
                  :result_type

      def initialize(plan, cols, id, result_type=nil, idref=nil, colref=nil)
        @id = id
        @idref = idref
        @colref = colref
        @result_type = result_type
        @plan = plan
        @cols = cols
      end

      def to_xml
        attributes = { :id => id }
        attributes.merge!({ :idref => idref }) if idref
        attributes.merge!({ :colref => colref }) if colref

        query_plan(attributes) do
          p = []
          p << properties do
                 property(:name => :overallResultType, :value => result_type.to_xml)
               end if result_type
          p << plan.serialize
          p.join
        end
      end
    end

   
    class QueryPlanBundle
    private
#      def collect_surrogates(surr)
#        lplans = []
#        surr.each do |attr,q_in|
#          lplans << [SerializeRelation.new(
#                      q_in.side_effects.plan, q_in.plan,
#                      Iter.new(1), Pos.new(1), q_in.column_structure.items),
#                     q_in.column_structure]
#          lplans += collect_surrogates(q_in.surrogates)
#        end
#        lplans
#      end

      def collect_surrogates(items, last_id, surr)
        next_id= last_id + 1
        surr.surrogates.map do |attr,qin|
          plan = qin.plan
          cols = qin.column_structure
          side = qin.side_effects.plan
          surr = qin.surrogates

          colref = items.index(attr) + 1

          ser = SerializeRelation.new(
                  side, plan,
                  Iter.new(1), Pos.new(1), cols.items)
          qp = QueryPlan.new(
                 ser, cols, next_id, nil, last_id, colref)
          qps = collect_surrogates(cols.items, next_id, surr)
          next_id += qps.flatten.size + 1
          [qp] + qps
        end
      end

    public 
      include Locomotive::XML
      def_node :query_plan_bundle,
               :csstructure

    
      XML_Prolog = '<?xml version="1.0" encoding="UTF-8"?>'+"\n"
    
      attr_accessor :query_plans
      attr :cs_structure

      def initialize(qin, type)
        plan = qin.plan
        cols = qin.column_structure
        side = qin.side_effects.plan
        surr = qin.surrogates

        ser = SerializeRelation.new(
                side, plan,
                Iter.new(1), Pos.new(1),
                cols.items)

        qp = QueryPlan.new(ser, cols, 0, type)
        self.query_plans = [qp, collect_surrogates(cols.items, 0, surr)].flatten
      end

      def to_xml
        XML_Prolog +
        query_plan_bundle do
          query_plans.map do |qp|
            qp.to_xml
          end.join
        end
      end
    
      def clone
        QueryPlanBundle.new( logical_query_plans )
      end
    end

  end

end
