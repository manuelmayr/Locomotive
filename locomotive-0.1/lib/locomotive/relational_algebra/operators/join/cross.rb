module Locomotive

  module RelationalAlgebra
    
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

  end

end
