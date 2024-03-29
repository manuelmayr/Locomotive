module Locomotive

  module RelationalAlgebra

    class Cast < Unary
      def_node :_type_
    
      attr_accessor :res,
                    :type,
                    :item 
      def_sig :res=, ConstAttribute
      def_sig :type=, RType
      def_sig :item=, ConstAttribute
    
      def initialize(op, res, item, type)
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
        self.schema = op.schema + Schema.new({ self.res => [self.type] })
        super(op)
      end
    
      def xml_content
        content do
          [column(:name => res.to_xml, :new => true),
           column(:name => item.to_xml, :new => false),
           _type_(:name => type.to_xml)].join
        end
      end
    
      def clone
        Cast.new(
          child.clone,
          res.clone,
          item.clone,
          type.clone)
      end
    
      def set(var,plan)
        Cast.new(
          child.set(var,plan),
          res.clone,
          item.clone,
          type.clone)
      end
    end

  end

end
