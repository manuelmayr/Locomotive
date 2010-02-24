module Locomotive

module AstHelpers

class TraverseStrategy
  def traverse(ast, &block)
    raise "Called abstract method traverse"
  end
end

class PrefixTraverse < TraverseStrategy
  def traverse(ast, &block)
    block.call(ast)
    traverse(ast.left_child,  &block) if ast.has_left_child?
    traverse(ast.right_child, &block) if ast.has_right_child?
    # return nothing
    return
  end
end

class PostfixTraverse < TraverseStrategy
  def traverse(ast, &block)
    traverse(ast.left_child,  &block) if ast.has_left_child?
    traverse(ast.right_child, &block) if ast.has_right_child?
    block.call(ast)
    # return nothing
    return
  end
end

class InfixTraverse < TraverseStrategy
  def traverse(ast, &block)
    traverse(ast.left_child,  &block) if ast.has_left_child?
    block.call(ast)
    traverse(ast.right_child, &block) if ast.has_right_child?
    # return nothing
    return 
  end
end

end

end
