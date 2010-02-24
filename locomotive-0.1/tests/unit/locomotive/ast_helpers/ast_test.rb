require 'test/unit'
require 'importer'
require 'pp'

import 'locomotive/ast_helpers/ast'

module Locomotive

module AstHelpers

module Tests

module Unit

class TestAst
  include AstNode
end

class AstTest < Test::Unit::TestCase

 def setup
   @test_ast = TestAst.new(
                :kind1,
                1,
                TestAst.new(
                  :kind2,
                  nil),
                TestAst.new(
                  :kind3,
                  nil))
 end
 
 def test_kind
   assert_equal :kind1, @test_ast.kind
   assert_equal :kind2, @test_ast.left_child.kind
   assert_equal :kind3, @test_ast.right_child.kind
 end
 
 def test_leafs
   assert !@test_ast.is_leaf?,
          "root node shouldn't be a leaf"
   assert @test_ast.left_child.is_leaf?,
          "left child should be a leaf"
   assert @test_ast.right_child.is_leaf?,
          "right child should be a leaf"
 end
 
 def test_value
   assert_equal 1,   @test_ast.value
   assert_equal nil, @test_ast.left_child.value
   assert_equal nil, @test_ast.right_child.value
 end
  
end

end

end

end

end
