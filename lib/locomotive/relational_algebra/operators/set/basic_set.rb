module Locomotive

  module RelationalAlgebra

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

  end

end
