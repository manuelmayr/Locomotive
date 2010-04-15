module Locomotive

  module RelationalAlgebra

    class Eqjoin < Join
      attr_accessor :item1
      def_sig :item1=, Attribute
      attr_accessor :item2
      def_sig :item2=, Attribute
    
    
      def initialize(op1,op2,it1,it2)
        self.item1,
        self.item2 = it1, it2
        super(op1,op2)
      end
    
      def left_and_right(op1,op2)
        unless op1.schema.attributes?([self.item1])
          raise CorruptedSchema,
                "Schema #{op1.schema.attributes} does not " \
                "contain all attributes of #{item1}."
        end
        unless op2.schema.attributes?([self.item2])
          raise CorruptedSchema,
                "Schema #{op2.schema.attributes} does not " \
                "contain all attributes of #{item2}."
        end
        self.schema = op1.schema + op2.schema
        super(op1,op2)
      end
    
      def xml_content
        content do
          [column(:name => item1.to_xml, :new => false, :position => 1),
           column(:name => item2.to_xml, :new => false, :position => 2)
          ].join
        end
      end
    
      def clone
        Eqjoin.new(left.clone,right.clone,
                   item1.clone, item2.clone)
      end
    
      def set(var,plan)
        Eqjoin.new(
          left.set(var,plan),
          right.set(var,plan),
          item1.clone,
          item2.clone)
      end
    end
    
  end 

end
