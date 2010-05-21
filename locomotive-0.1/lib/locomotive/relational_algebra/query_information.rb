module Locomotive

  module RelationalAlgebra

    # Forward declaration 
    class QueryInformationNode; end
    
    class SurrogateList
      protected
    
      attr_accessor :surrogates
      def_sig :surrogates=, { ConstAttribute => QueryInformationNode }
    
      public
      delegate :[],
               :to_a,
               :each,
               :keys,
               :empty?,
               :first,
               :to => :surrogates
    
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
        self.clone.surrogates.delete_if(&lambda)
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

        q1, q2 = q1_in.plan, q2_in.plan
        cols_q1, itbls_q1 = q1_in.column_structure, q1_in.surrogates
        iter_, iter__, item_, item__ = Iter.new(2), Iter.new(3),
                                       Item.new(2), Item.new(3)
      
        # (1)
        q = q1.attach(AttachItem.new(iter_, RAtomic.new(1, RNat.type))).
               union(q2.attach(AttachItem.new(iter_, RAtomic.new(2, RNat.type)))).
               row_num(item_, [], [Iter.new(1), iter_, Pos.new(1)])
        
        #(2)
        c_new = (self.keys + itbl_2.keys).max.inc(100)

        q_ = q_0.project( iter_ => [iter__],
                          item_ => [item__],
                          c     => [c_new] ).
                 theta_join(q, [Equivalence.new(iter__, iter_),
                                Equivalence.new(c_new, Iter.new(1))] ).
                 project( { item__ => [Iter.new(1)],
                            Pos.new(1) => [Pos.new(1)],
                            item_ => itbls_q1.keys  }.
                            merge(
                              (cols_q1 - itbls_q1.keys).items.collect do |col|
                                [col, [col]]
                              end.to_hash) )

         # (3)          
         itbl_ = q1_in.surrogates.itapp(q, q2_in.surrogates)
         # (4)
         itbl__ = SurrogateList.new(
                         self.delete_if { |k,v| k == c}).itapp(q_0,
                                               SurrogateList.new(itbl_2.delete_if { |k,v| k == c}))
         # (5)
         SurrogateList.new( { c => QueryInformationNode.new(
                                     q_, cols_q1, itbl_) } ) + itbl__
      end
      def_sig :itapp, Operator, SurrogateList

      def itsel(q_0)
        return SurrogateList.new({}) if self.empty? 

        c, c_ = self.first.first, self.keys.max.inc
        cols, itbls, q = self[c].column_structure, self[c].surrogates, self[c].plan

        # (1)
        q_ = q.equi_join(q_0.project( c => [c_]), Iter.new(1), c_).
               project( [Iter.new(1), Pos.new(1)] + cols.items )

        itbls_ = itbls.itsel(q_)
        itbls__ = SurrogateList.new(
                    self.clone.delete_if { |k,v| k == c }).itsel(q_0)

        SurrogateList.new(
          { c => QueryInformationNode.new(q_, cols, itbls_) }.
          merge( itbls__.to_a.to_hash ) )
      end

      def set(var, plan)
        self.map do |item, itbl|
          [item,QueryInformationNode.new(itbl.plan.set(var, plan), 
                                         itbl.column_structure,
                                         itbl.surrogates.set(var,plan))]
        end
      end
    
      def clone
        SurrogateList.new( surrogates.map { |k,v| [k.clone,v.clone] }.to_hash )
      end

      def filter_and_adapt(items)
        item_min = items.min
        # we are modifying the structure itself
        # so we have to clone it (sideeffect)
        surr_new = self.clone
        surr_new.delete_if do |it, itbl|
          !items.member?(it)
        end

       # adapt the keys
       surr_new.keys.each { |k| k.dec!(item_min.id - 1) }
       surr_new
     end
    end

    class ColumnStructureEntry
    end

    class OffsetType < ColumnStructureEntry
      attr_reader :offset,
                  :type

      def initialize(offset, type)
        @offset = offset
        @type   = type
      end

      def items
        [offset]
      end

      def clone
        OffsetType.new(offset.clone,
                       type.clone)
      end
    end

    class AttributeColumnStructure < ColumnStructureEntry
      attr_reader :attribute,
                  :column_structure

      def initialize(attribute, cs)
        @attribute = attribute
        @column_structure = cs
      end

      def items
        column_structure.items
      end

      def clone
        AttributeColumnStructure.new(attribute.clone,
                                     column_structure.clone)
      end
    end

    class ColumnStructure
      private

        def to_cs_entry(entry)
          return entry if OffsetType === entry or AttributeColumnStructure === entry

          raise ArgumentError,
                "entry is not a column_structure_entry" if !(Array === entry and
                                                             entry.size == 2)
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
          end[0]
        end

        def search_by_item(offset)
          entries.select do |entry|
            entry.offset == offset
          end[0]
        end

      public
        attr_reader :entries

        delegate :first,
                 :map,
                 :collect,
                 :to => :entries

        def initialize(entries)
          @entries = entries.map do |entry|
                       to_cs_entry(entry)
                     end
        end

        def add(entries)
          entries_ = entries
          entries_ = entries.entries if ColumnStructure === entries
          ColumnStructure.new(self.entries + entries)
        end

        def [](attribute_index)
          # just look on the surface if you find the right attribute
          case 
            when Fixnum === attribute_index then
              entries[attribute_index]
            when Symbol === attribute_index then 
              attribute = Attribute.new(attribute_index)
              search_by_attribute(attribute).column_structure
            when Attribute === attribute_index then
              search_by_attribute(attribute_index).column_structure
            when Item === attribute_index then
              ColumnStructure.new([search_by_item(attribute_index)])
            else 
              raise ArgumentError, "[] in ColumnStructure"
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
          @side.clone + to_side_effect(side_effect))
      end

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
                     "cs_structure doesn't seem to be a paylad_list"
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
          when SideEffects == side_effects then
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
    
      def clone
        QueryInformationNode.new(plan.clone,
                                 column_structure.clone,
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
    private
      def collect_surrogates(surr)
        lplans = []
        surr.each do |attr,q_in|
          lplans << SerializeRelation.new(
                      q_in.side_effects.plan, q_in.plan,
                      Iter.new(1), Pos.new(1), q_in.column_structure.items)
          lplans += collect_surrogates(q_in.surrogates)
        end
        lplans
      end

    public 
      include Locomotive::XML
      def_node :query_plan_bundle,
               :query_plan,
               :properties, :property
    
      XML_Prolog = '<?xml version="1.0" encoding="UTF-8"?>'+"\n"
    
      attr_accessor :logical_query_plans
      def_sig :logical_query_plans=, [Operator]
    
      def initialize(op)
        SerializeRelation.new(
          op.side_effects.plan, op.plan,
          Iter.new(1), Pos.new(1), op.column_structure.items)

        lplans = []
        lplans <<
           SerializeRelation.new(
              op.side_effects.plan, op.plan,
              Iter.new(1), Pos.new(1), op.column_structure.items)
           
        lplans += collect_surrogates(op.surrogates)
        
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
