module Locomotive

  module RelationalAlgebra
  
    # Represents a Relational Algebra node
    # Such a node has
    #  * the behaviour of a composite pattern
    #  * and node specific annotations
    class RelAlgAstNode
      include AstHelpers::AstNode
      include AstHelpers::Annotations
    end
  
  end

end

