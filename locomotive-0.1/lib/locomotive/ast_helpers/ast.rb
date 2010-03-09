require "#{File.dirname(__FILE__)}/ast_traversal"


module Locomotive

module AstHelpers

# Implements the composite behaviour, thus a node with
# two children.
module AstNode
  private
  
  DEFAULT_TRAVERSE_STRATEGY = PrefixTraverse.new

  public

  attr_accessor :kind,
                :value,
                :owner

  attr_reader :left_child,
              :right_child

  # The owner denotes the parent
  # of this node

  # Initialize the node with values.</b>
  # An <b>A</b>stract <b>S</b>yntax <b>T</b>ree-Node
  # has a
  #   1. kind
  #   2. value
  #   3. a left child
  #   4. a right child
  #   5. some node specific annotations
  #
  # The values 2. - 5. can be omitted because there can be
  # some nodes with a kind only (e.g. separators).
  # A node with neither left- nor right-child is a leaf-node.
  def initialize(kind,
                 value = nil,
                 left = nil,
                 right = nil)
    self.owner = nil
    self.kind, self.value = kind, value
    self.left_child  = left  if left  != nil
    self.right_child = right if right != nil
    self.traverse_strategy = DEFAULT_TRAVERSE_STRATEGY
  end

  # Sets a new left child 
  # and sets the owner which is the
  # actual instance
  def left_child=(child)
    child.owner = self
    @left_child = child
  end

  # Sets a new right child
  # and sets the owner which is the
  # actual instance 
  def right_child=(child)
    child.owner  = self
    @right_child = child
  end

  def has_left_child?
    self.left_child != nil
  end

  def has_right_child?
    self.right_child != nil
  end

  # checks whether the node is a leaf
  # or not
  def is_leaf?
    self.left_child == nil and
    self.right_child == nil
  end

  def traverse_strategy=(strategy)
    @strategy = strategy
    self.left_child.traverse_strategy = strategy if self.has_left_child?
    self.right_child.traverse_strategy = strategy if self.has_right_child?
  end

  # Traverses the ast with a given
  # strategy. If nothing given simple
  # prefix-traversal is used
  def traverse(strategy=nil, &block)
    @strategy = strategy || DEFAULT_TRAVERSE_STRATEGY
    @strategy.traverse(self, &block)
  end

end

end

end
