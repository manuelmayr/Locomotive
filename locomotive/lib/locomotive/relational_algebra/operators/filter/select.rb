module Locomotive

  module RelationalAlgebra

    class Select < Unary
      attr_accessor :item
    
      def initialize(op,  item)
        self.item = item
        super(op)
      end
    
      def child=(op)
        unless op.schema.attributes?([item])
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{item}."
        end
        
        unless op.schema[item].member? RBool.instance
          raise CorruptedSchema,
                "#{item}(#{op.schema[item]}) doesn have the type Boolean."
        end
    
        self.schema = op.schema.clone
        super(op)
      end
    
      def xml_content
        content do
          column :name => item.to_xml, :new => false
        end
      end
    
      def clone
        Select.new(
          self.child.clone,
          self.item.clone)
      end
    
      def set(var,plan)
        Select.new(
          child.set(var,plan),
          item.clone)
      end
    end

  end

end
