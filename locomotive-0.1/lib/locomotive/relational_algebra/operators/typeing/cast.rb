module Locomotive

  module RelationalAlgebra

    class Cast < Unary
      def_node :_type_
    
      attr_accessor :res,
                    :type,
                    :item 
      def_sig :res, Attribute
      def_sig :type, Type
      def_sig :item, Attribute
    
      def initialize(op, res, type, item)
        self.res,
        self.type,
        self.item = res, type, item
        super(op)
      end
    
      def child=(op)
        unless op.schema.attributes?([item])
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{item}."
        end
        self.schema = op.schema + { self.res => [self.type] }
        super(op)
      end
    
      def xml_content
        content do
          column :name => res.to_xml, :new => true
          column :name => item.to_xml, :new => false
          _type_ :name => type.to_xml
        end
      end
    
      def clone
        Cast.new(
          child.clone,
          res.clone,
          type.clone,
          item.clone)
      end
    
      def set(var,plan)
        Cast.new(
          child.set(var,plan),
          res.clone,
          type.clone,
          item.clone)
      end
    end

  end

end
