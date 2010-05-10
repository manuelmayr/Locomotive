module Locomotive

  module RelationalAlgebra

    class PayloadList
      private
    
      attr_accessor :attributes
      def_sig :attributes=, [Attribute]
    
      public
      delegate :[],
               :to_a,
               :collect,
               :max,
               :to => :attributes
    
      def initialize(ary)
        self.attributes = ary
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
      def_sig :surrogates=, { Attribute => QueryInformationNode }
    
      public
      delegate :[],
               :to_a,
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
        q = RowId.new(
              Union.new(
                Attach.new(
                  q1_in.plan,
                  AttachItem.new(Iter(2),RAtomic.new(2, RNat.instance))),
                Attach.new(
                  q2_in.plan,
                  AttachItem.new(Iter(2),RAtomic.new(1, RNat.instance)))),
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
    
      def initialize(plan, payloads, surrogates=nil, methods={})
        self.plan,
        self.payload_items,
        self.surrogates = plan, PayloadList.new(payloads),
                          surrogates.nil? ? SurrogateList.new({}) : surrogates
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
