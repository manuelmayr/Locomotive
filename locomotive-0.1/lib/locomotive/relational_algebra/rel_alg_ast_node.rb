module Locomotive

  module RelationalAlgebra
  
    # Represents a Relational Algebra node
    # Such a node has
    #  * the behaviour of a composite pattern
    #  * and node specific annotations
    class RelAlgAstNode
      include AstHelpers::AstNode
      include AstHelpers::Annotations

      [:project,
       :row_num, :row_id, :rank, :row_rank].each do |op|
        define_method(op) do |*args|
          Kernel.const_get(op.classify).new(self, *args)
        end
      end
    end
  
  end

end

