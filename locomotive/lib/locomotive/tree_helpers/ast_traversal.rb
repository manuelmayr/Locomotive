module Locomotive

module AstHelpers

class TraverseStrategy
  def clean_visited_list
    @visited_nodes = {}
  end

  def initialize
    clean_visited_list
  end

  def traverse(ast, &block)
    @visited_nodes = 
      @visited_nodes.merge( { ast.object_id => true } )
  end
end

class PreOrderTraverse < TraverseStrategy
  def initialize
    super
  end

  def traverse(ast, &block)
    return if @visited_nodes[ast.object_id]
    block.call(ast)
    super(ast, &block)
    traverse(ast.left_child,  &block) if ast.has_left_child?
    traverse(ast.right_child, &block) if ast.has_right_child?
    # return nothing
    return
  end
end

class PostOrderTraverse < TraverseStrategy
  def initialize
    super
  end

  def traverse(ast, &block)
    return if @visited_nodes[ast.object_id]
    traverse(ast.left_child,  &block) if ast.has_left_child?
    traverse(ast.right_child, &block) if ast.has_right_child?
    block.call(ast)
    super(ast, &block)
    # return nothing
    return
  end
end

class InOrderTraverse < TraverseStrategy
  def initialize
    super
  end 

  def traverse(ast, &block)
    return if @visited_nodes[ast.object_id]
    traverse(ast.left_child,  &block) if ast.has_left_child?
    block.call(ast)
    super(ast, &block)
    traverse(ast.right_child, &block) if ast.has_right_child?
    # return nothing
    return 
  end
end

end

end
