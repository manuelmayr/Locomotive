module Locomotive

  module RelationalAlgebra
  
    # Represents a Relational Algebra node
    # Such a node has
    #  * the behaviour of a composite pattern
    #  * and node specific annotations
    class RelAlgAstNode
      include AstHelpers::AstNode
      include AstHelpers::Annotations

      [:project, :attach,
       :or, :and,
       :aggr,
       :function,
       :select,
       :difference, :union,
       :cross, :equi_join, :theta_join,
       :equal, :greater_then, :greater_equal_then, :less_then, :less_equal_then,
       :row_num, :row_id, :rank, :row_rank,
       :serialize_relation].each do |op|
        define_method(op) do |*args|
          Kernel.const_get(op.classify).new(self, *args)
        end
      end
    end
  
  end

end

