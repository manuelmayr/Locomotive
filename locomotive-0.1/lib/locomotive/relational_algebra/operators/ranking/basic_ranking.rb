module Locomotive

  module RelationalAlgebra

    class Numbering < Unary
      attr_accessor :res,
                    :sort_by
      def_sig :res=, Attribute
      def_sig :sort_by=, SortList
    
      def initialize(op, res, sortby)
        self.res,
        self.sort_by = res, sortby || SortList.new({}) 
        super(op)
      end
    
      def child=(op)
        unless op.schema.attributes?(self.sort_by.attributes)
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{sort_by.attributes}."
        end
        self.schema = op.schema + Schema.new({ res => [Nat.instance] })
        super(op)
      end
    
      def xml_content
        content do
          [column( :name => res.to_xml, :new => true),
           sort_by.to_xml].join
        end
      end
    
      def clone
        self.class.new(child.clone,
                       res.clone,
                       sort_by.clone)
      end
    
      def set(var, plan)
        self.class.new(
          child.set(var,plan),
          res.clone,
          sort_by.clone)
      end
    end


  end

end
