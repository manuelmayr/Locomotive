module Locomotive

  module RelationalAlgebra
    
    # represents a variant operator of the
    # relational algebra
    class Operator < RelAlgAstNode
      include Locomotive::XML
      def_node :node, :content, :column, :edge
    
      attr_accessor :schema
      def_sig :schema=, Schema
    
      def initialize
        raise AbstractClassError,
              "#{self.class} is an abstract class" if self.class == Operator
        super()
        self.schema = Schema.new({})
      end
    
      def xml_schema
        self.schema.to_xml
      end
    
      def xml_content
        content()
      end
    
      def xml_kind
        self.class.to_s.split("::").last.downcase.to_sym
      end
    
      def to_xml
        cont_list = [ xml_schema,
                      xml_content ]
        cont_list << edge(:to => left_child.id) if has_left_child?
        cont_list << edge(:to => right_child.id) if has_right_child? 
        node :id => id,
             :kind => xml_kind do
          cont_list.join
        end
      end
    
      # returns all free variables in this plan
      def free
        # attention: for convenience we use
        # the underlying ast framework
        fv = []
        fv += left_child.free if has_left_child?
        fv += right_child.free if has_right_child?
        fv
      end
    
      # returns all bound variables in this plan
      def bound
        # attention: for convenience we use
        #  the underlying ast framework
        bv = []
        bv += left_child.bound if has_left_child?
        bv += right_child.bound if has_right_child?
        bv
      end
    end

    #
    # A leaf doesn't have any child
    #
    class Leaf < Operator
    #  undef left_child=
    #  undef left_child
    #  undef has_left_child?
    #  undef right_child=
    #  undef right_child
    #  undef has_right_child?
      def initialize()
        raise AbstractClassError,
              "#{self.class} is an abstract class" if self.class == Leaf
        super()
      end
    
      def set(var,plan)
        self.clone
      end
    end
  
    #
    # An unary Operator has exactly one child
    #
    class Unary < Operator
      # undefine all methods to access
      # the right child
    #  undef right_child=
    #  undef right_child
    #  undef has_right_child?
    
      # since we have only one child for this
      # type of operators, we define a shortcut
      alias :child :left_child
      alias :child= :left_child=
      def_sig :child=, Operator
    
      alias :child? :has_left_child?
    
      def initialize(op)
        raise AbstractClassError,
              "#{self.class} is an abstract class" if self.class == Unary
        super()
        self.child = op
      end
    end
    
    #
    # A binary operator has exactly two children
    # 
    class Binary < Operator
      # getter and setters for left and
      # right children by defining shortcuts
      alias :left :left_child
      alias :right :right_child
      alias :left? :has_left_child?
      alias :right? :has_right_child?
    
      #alias :left= :left_child=
      #def_sig :left=, Operator
      #alias :right= :right_child=
      #def_sig :right=, Operator
    
      def left_and_right(op1, op2)
        self.left_child = op1
        self.right_child = op2 
      end
    
      def initialize(op1, op2)
        raise AbstractClassError,
              "#{self.class} is an abstract class" if self.class == Binary
        super()
        left_and_right(op1,op2)
      end
    end
     
  end

end
