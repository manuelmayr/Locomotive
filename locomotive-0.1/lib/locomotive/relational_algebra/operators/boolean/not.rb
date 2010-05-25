module Locomotive

  module RelationalAlgebra

    class Not < Unary
      attr_accessor :res, :item
      def_sig :res=, ConstAttribute
      def_sig :item=, ConstAttribute
      
      def initialize(op, res, item)
        self.res,
        self.item = res, item
        super(op)
      end
      
      def child=(op)
        unless op.schema.attributes?([item])
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{item1}."
        end
  
        self.schema = op.schema +
                 Schema.new({ res => [RBool.instance] })
      
        super(op)
      end
      
      def xml_content
        content do
          [column(:name => res.to_xml, :new => true),
           column(:name => item.to_xml, :new => false)].join
        end
      end
      
      def xml_kind
        self.class.to_s.split('::').last.downcase.to_sym
      end
      
      def clone
       Not.new(child.clone,
               res.clone,
               item.clone)
      end
      
      def set(var, plan)
        self.class.new(
          child.set(var,plan),
          res.clone,
          item.clone)
      end
    end
  
  end

end
