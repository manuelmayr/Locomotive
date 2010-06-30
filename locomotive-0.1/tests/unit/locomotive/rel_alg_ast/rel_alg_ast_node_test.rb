require 'test_helper'

module Locomotive

  module RelAlgAst
  
    module Tests
    
      module Unit
      
        class RubyAstTest < Test::Unit::TestCase
        
          def setup
            @relalg_ast = RelAlgAstNode.new(
                                    :plus,
                                    nil,
                                    RelAlgAstNode.new(
                                      :int,
                                      1),
                                    RelAlgAstNode.new(
                                      :int,
                                      2))
        
            @relalg_ast.ann_id             = 3
            @relalg_ast.left_child.ann_id  = 1
            @relalg_ast.right_child.ann_id = 2
          end
        
          def test_tree_properties
            assert !@relalg_ast.is_leaf?,
                   "root node shouldn't be a leaf"
            assert @relalg_ast.left_child.is_leaf?,
                   "left child should be a leaf"
            assert @relalg_ast.left_child.is_leaf?,
                   "right child should be a leaf"
        
            assert_equal :plus, @relalg_ast.kind
            assert_equal :int,  @relalg_ast.left_child.kind
            assert_equal :int,  @relalg_ast.right_child.kind
          end
          
          def test_annotations
            assert_equal 3, @relalg_ast.ann_id
            assert_equal 1, @relalg_ast.left_child.ann_id 
            assert_equal 2, @relalg_ast.right_child.ann_id 
          end
        end
      
      end
    
    end
  
  end 

end
