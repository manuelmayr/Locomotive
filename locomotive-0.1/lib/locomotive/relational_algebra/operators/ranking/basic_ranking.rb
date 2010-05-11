module Locomotive

  module RelationalAlgebra

    class Numbering < Unary
      attr_reader :res,
                  :sort_by
    
      def initialize(op, res, sortby)
        @res = res
        @sort_by = case
                     when Array === sortby then 
                       SortList.new( 
                          sortby.map { |si|
                            [si, Ascending.instance]
                          }.to_hash )
                     when Hash === sortby then 
                       SortList.new(sortby)
                   end
        super(op)
      end
    
      def child=(op)
        unless op.schema.attributes?(sort_by.attributes)
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{sort_by.attributes}."
        end
        self.schema = op.schema + Schema.new({ @res => [RNat.instance] })
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
