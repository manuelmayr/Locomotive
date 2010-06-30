module Locomotive

  module RelationalAlgebra

    class RowNum < Numbering
      def_node :column
      
      attr_accessor :part
      def_sig :part=, [ConstAttribute]
    
      def initialize(op, res, part, sortby)
        self.part = part
        super(op,res,sortby)
      end
    
      def child=(op)
        unless op.schema.attributes?(part)
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{part}."
        end
        super(op)
      end
    
      def xml_content
        pos = -1
        content do
          [column(:name => res.to_xml, :new => true),
           sort_by.to_xml,
           part.collect do |p|
             column :name => p.to_xml,
                    :function => :partition,
                    :position => pos += 1,
                    :new => false
           end.join].join
        end
      end
    
      def clone
        RowNum.new(child.clone,
                   res.clone,
                   part.clone,
                   sort_by.clone)
      end
    
      def set(var,plan)
        RowNum.new(
          child.set(var,plan),
          res.clone, part.clone, sort_by.clone)
      end
    end

  end

end
