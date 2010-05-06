module Locomotive

  module RelationalAlgebra
    
    class AttachItem
      include Locomotive::XML
      def_node :column
    
      attr_accessor :attribute
      def_sig :attribute=, Attribute
      attr_accessor :atom
      def_sig :atom=, RAtomic
    
      def initialize(attr, atom)
        self.attribute,
        self.atom = attr, atom
      end
    
      def to_xml
        column :name => attribute.to_xml,
               :new => true do
          atom.to_xml
        end 
      end
    
      def clone
        AttachItem.new(attribute, atom)
      end
    end
    
    
    
    class Attach < Unary
      attr_accessor :item
      def_sig :item=, AttachItem
    
      def initialize(op, item)
        self.item = item
        super(op)
      end
    
      def child=(op)
        self.schema = op.schema +
                 Schema.new({ item.attribute => [item.atom.type] })
        super(op)
      end
    
      def xml_content
        content do
          item.to_xml
        end
      end
    
      def clone
        Attach.new(child.clone, item.clone)
      end
    
      def set(var, plan)
        Attach.new(
          child.set(var,plan),
          item.clone)
      end
    end
   
  end 

end 
