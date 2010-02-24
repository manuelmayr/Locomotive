module Locomotive

module RubyAst

# Represents a Ruby AST node.
# Such a node has
#  * the behaviour of a composite pattern
#  * and node specific annotations
class RubyAstNode
  include AstHelpers::AstNode
  include AstHelpers::Annotations
end

end

end
