require 'test/unit'
require 'pp'
require 'importer'

import 'locomotive/ruby_ast/ruby_ast_node'

module Locomotive

module RubyAst

module Tests

module Unit

class RubyAstTest < Test::Unit::TestCase

  def setup
    @ruby_ast = RubyAstNode.new(
                            :plus,
                            nil,
                            RubyAstNode.new(
                              :int,
                              1),
                            RubyAstNode.new(
                              :int,
                              2))

    @ruby_ast.ann_id             = 3
    @ruby_ast.left_child.ann_id  = 1
    @ruby_ast.right_child.ann_id = 2
  end

  def test_tree_properties
    assert !@ruby_ast.is_leaf?,
           "root node shouldn't be a leaf"
    assert @ruby_ast.left_child.is_leaf?,
           "left child should be a leaf"
    assert @ruby_ast.left_child.is_leaf?,
           "right child should be a leaf"

    assert_equal :plus, @ruby_ast.kind
    assert_equal :int,  @ruby_ast.left_child.kind
    assert_equal :int,  @ruby_ast.right_child.kind
  end
  
  def test_annotations
    assert_equal 3, @ruby_ast.ann_id
    assert_equal 1, @ruby_ast.left_child.ann_id 
    assert_equal 2, @ruby_ast.right_child.ann_id 
  end

  def test_traversal
    # performs a simple prefix traversal and gives a unique id
    # to every node
    #
    #       (:plus, 1)
    #       /        \
    #      /          \
    #   (:int, 2)   (:int, 3)
    i = 1
    @ruby_ast.traverse do |ast|
                         ast.ann_prefix_id = i
                         i += 1
                       end
    assert_equal 1, @ruby_ast.ann_prefix_id
    assert_equal 2, @ruby_ast.left_child.ann_prefix_id
    assert_equal 3, @ruby_ast.right_child.ann_prefix_id

    # performs a simple postfix traversal and gives a unique id
    # to every node
    #
    #       (:plus, 3)
    #       /        \
    #      /          \
    #   (:int, 1)   (:int, 2)
    i = 1
    @ruby_ast.traverse(AstHelpers::PostfixTraverse.new) do |ast|
                                                          ast.ann_postfix_id = i
                                                          i += 1
                                                        end
    assert_equal 3, @ruby_ast.ann_postfix_id
    assert_equal 1, @ruby_ast.left_child.ann_postfix_id
    assert_equal 2, @ruby_ast.right_child.ann_postfix_id
  end

end

end

end

end 

end
