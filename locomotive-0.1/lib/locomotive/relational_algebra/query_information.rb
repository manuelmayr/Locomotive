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
               :delete_if,
               :to => :surrogates
    
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
        q = RowNum.new(
              Union.new(
                Attach.new(
                  q1_in.plan,
                  AttachItem.new(Iter.new(2),RAtomic.new(1, RNat.instance))),
                Attach.new(
                  q2_in.plan,
                  AttachItem.new(Iter.new(2),RAtomic.new(2, RNat.instance)))),
              Item.new(2), [],
              [Iter.new(1), Iter.new(2), Pos.new(1)])
        #(2)
        c_new = c.class.new(c.id + 100)
        q_prime = Project.new(
                    ThetaJoin.new(
                      q,
                      Project.new(
                        q_0,
                        { Iter.new(2) => [ Iter.new(3) ],
                          Item.new(2) => [ Item.new(3) ],
                          c           => [ c_new ] }),
                      PredicateList.new( Equivalence.new(Iter.new(2), Iter.new(3)),
                                         Equivalence.new(Iter.new(1), c_new) )),
                   { Item.new(3) => [ Iter.new(1) ],
                     Pos.new(1)  => [ Pos.new(1) ] }.merge(
                     { Item.new(2) => q1_in.surrogates.keys }).merge(
                       Hash[*(q1_in.column_structure - q1_in.surrogates.keys).items.collect do |col|
                         [col, [col]]
                       end.flatten_once]))
         # (3)          
         itbl_prime = q1_in.surrogates.itapp(q, q2_in.surrogates)
         # (4)
         itbl_2prime = SurrogateList.new(
                         self.delete_if { |k,v| k == c}).itapp(q_0,
                                               SurrogateList.new(itbl_2.delete_if { |k,v| k == c}))
         # (5)
         SurrogateList.new( { c => QueryInformationNode.new(
                                     q_prime, q1_in.column_structure, itbl_prime) } ) + itbl_2prime
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
    
      def clone
        SurrogateList.new( surrogates.clone )
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

      def clone
        OffsetType.new(offset.clone,
                       type.clone)
      end
    end

    class AttributeColumnStructure < ColumnStructureEntry
      attr_reader :attribute
                  :column_structure

      def initialize(attr, cs)
        @attribute = attr
        @column_structure = cs
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

        def search_by_attribute(attr)
          entries.select do |entry|
            e.attribute == attribute
          end[0]
        end

        def search_by_item(offset)
          entries.select do |entry|
            e.offset == offset
          end[0]
        end

      public
        attr_reader :entries

        delegate :first,
                 :to => :entries

        def initialize(entries)
          @entries = entries.map do |entry|
                       to_cs_entry(entry)
                     end
        end

        def [](attribute_index)
          # just look on the surface if you find the right attribute
          case 
            when Fixnum === attribute_index then
              entries[attribute_index]
            when Symbol === attribute_index then 
              attribute = Attribute.new(attribute_index)
              search_by_attribute(attribute)
            when Attribute === attribute_index then
              search_by_attribute(attribute_index)
            when Item === attribute_index then
              search_by_item(attribute_index)
            else 
              raise ArgumentError, "[] in ColumnStructure"
          end
        end

        def -(array)
          # FIXME support for attributes
          ColumnStructure.new(
            entries.clone.delete_if do |entry|
              array.member? entry.offset
            end)
        end

        def clone
          ColumnStructure.new(
            *entries.map { |e| e.clone })
        end

        def items
          entries.map do |entry|
            case
              when OffsetType === entry then
                entry.offset
              when AttributeColumnStructure === entry then
                entry.column_structure.items
            end
          end.flatten
        end

        def max
          self.items.max
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

      public
      attr_accessor :plan,
                    :column_structure,
                    :surrogates,
                    :methods
    
      def_sig :plan=, Operator
      def_sig :column_structure=, ColumnStructure
      def_sig :surrogates=, SurrogateList
      def_sig :methods=, { Symbol => RelLambda }
    
      def initialize(plan, cs_structure, surrogates=nil, methods={})
        self.plan,
        self.column_structure,
        self.surrogates = plan, to_cs_structure(cs_structure),
                          to_surrogates(surrogates)
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
                      Nil.new, q_in.plan,
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
          Nil.new, op.plan,
          Iter.new(1), Pos.new(1), op.column_structure.items)

        lplans = []
        lplans <<
           SerializeRelation.new(
              Nil.new, op.plan,
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
