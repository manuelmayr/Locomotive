module Locomotive

  module RelationalAlgebra

    class Comparison < Unary
      def_node 
      attr_accessor :res,
                    :item1,
                    :item2
      def_sig :res=, Attribute
      def_sig :item1=, Attribute
      def_sig :item2=, Attribute
    
      def initialize(op, res, items)
        self.res,
        self.item1,
        self.item2 = res, items[0], items[1]
        super(op)
      end
    
      def child=(op)
        unless op.schema.attributes?([self.item1])
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{item1}."
        end
        unless op.schema.attributes?([self.item2])
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{item2}."
        end
    
        self.schema = op.schema + Schema.new({ self.res => [RBool.instance]})
        super(op)
      end
    
      def clone
        self.class.new(child.clone,
                       res.clone,
                       item1.clone,
                       item2.clone)
      end
    
      def set(var,plan)
        self.class.new(
          child.set(var,plan),
          res.clone,
          item1.clone,
          item2.clone)
      end
    
      def xml_content
            content do
          [column(:name => res.to_xml, :new => true),
           column(:name => item1.to_xml, :new => false, :position => 1),
           column(:name => item2.to_xml, :new => false, :position => 2)
          ].join
        end
    
      end
    end
    
  end

end 
