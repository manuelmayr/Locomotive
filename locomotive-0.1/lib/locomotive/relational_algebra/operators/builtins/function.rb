module Locomotive

  module RelationalAlgebra

    class Function < Unary;
      def_node :column, :kind
    
      attr_accessor :res,
                    :operator,
                    :items
      def_sig :res=, Attribute
      def_sig :operator=, Fun
      def_sig :items=, [Attribute]
    
     
      def initialize(op, operator, res, items)
        self.operator,
        self.res,
        self.items = operator, res, items
        super(op)
      end
    
      def child=(op)
        unless op.schema.attributes?(self.items)
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{items}."
        end
    
        self.schema = op.schema +
                        Schema.new( { res => op.schema[items.first] } )
        super(op)
      end
    
      def xml_kind
        :fun
      end
    
      def xml_content
        content do
          [
           kind(:name => operator.to_xml),
           column(:name => res.to_xml, :new => true),
           items.collect do |it|
             column :name => it.to_xml, :new => false
           end.join
          ].join
        end
      end
    
      def clone
        Function.new(child.clone,
                     operator.clone,
                     res.clone,
                     items.clone)
      end
    
      def set(var, plan)
        Function.new(
          child.set(var,plan),
          operator.clone,
          res.clone,
          items.clone) 
      end
    end
    
  end

end 
