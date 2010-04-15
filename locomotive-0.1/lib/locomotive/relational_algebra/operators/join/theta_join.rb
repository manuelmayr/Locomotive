module Locomotive

  module RelationalAlgebra

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

  end

end
