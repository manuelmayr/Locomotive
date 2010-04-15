module Locomotive

  module RelationalAlgebra

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
    
  end

end 
