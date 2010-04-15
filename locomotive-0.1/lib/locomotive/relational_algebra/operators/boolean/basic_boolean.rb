module Locomotive

  module RelationalAlgebra

    class BinOp < Unary
      attr_accessor :res, :item1, :item2
      def_sig :res=, Attribute
      def_sig :item1=, Attribute
      def_sig :item2=, Attribute
    
      def initialize(op, res, item1, item2)
        self.res,
        self.item1,
        self.item2 = res, item1, item2
        super(op)
      end
    
      def child=(op)
        unless op.schema.attributes?([item1])
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{item1}."
        end
        unless op.schema.attributes?([item2])
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{item2}."
        end
    
        self.schema = op.schema +
                 Schema.new({ res => [Bool.instance] })
    
        super(op)
      end
    
      def xml_content
        content do
          [column(:name => res.to_xml, :new => true),
           column(:name => item1.to_xml, :new => false, :position => 1),
           column(:name => item2.to_xml, :new => false, :position => 2)].join
        end
      end
    
      def xml_kind
        self.class.to_s.split('::').last.downcase.to_sym
      end
    
      def clone
        self.class.new(child.clone,
                       res.clone,
                       item1.clone,
                       item2.clone)
      end
    
      def set(var, plan)
        self.class.new(
          child.set(var,plan),
          res.clone,
          item1.clone,
          item2.clone)
      end
    end

  end

end
