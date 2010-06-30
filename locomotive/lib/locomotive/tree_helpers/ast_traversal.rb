module Locomotive

module AstHelpers

class TraverseStrategy
  def TraverseStrategy.traverse(ast, &block)
    raise "Called abstract method traverse"
  end
end

class PreOrderTraverse < TraverseStrategy
  def PreOrderTraverse.traverse(ast, &block)
    block.call(ast)
    traverse(ast.left_child,  &block) if ast.has_left_child?
    traverse(ast.right_child, &block) if ast.has_right_child?
    # return nothing
    return
  end
end

class PostOrderTraverse < TraverseStrategy
  def PostOrderTraverse.traverse(ast, &block)
    traverse(ast.left_child,  &block) if ast.has_left_child?
    traverse(ast.right_child, &block) if ast.has_right_child?
    block.call(ast)
    # return nothing
    return
  end
end

class InOrderTraverse < TraverseStrategy
  def InOrderTraverse.traverse(ast, &block)
    traverse(ast.left_child,  &block) if ast.has_left_child?
    block.call(ast)
    traverse(ast.right_child, &block) if ast.has_right_child?
    # return nothing
    return 
  end
end

end

end
