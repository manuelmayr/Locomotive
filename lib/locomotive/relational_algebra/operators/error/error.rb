module Locomotive

  module RelationalAlgebra

    class Error < Binary
      attr_accessor :item
      def_sig :item=, ConstAttribute

      def initialize(op1, op2, item)
        self.item = item
        super(op1, op2)
      end

      def left_and_right=(op1, op2)
        unless op.schema.attributes?([item])
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{item}."
        end

        # set the schema to its right child
        self.schema = op2.schema
      end

      def xml_kind
        :error
      end

      def xml_content
        content do
          column :name => item.to_xml, :new => false
        end
      end

      def clone
        Error.new(
          left.clone, right.clone,
          item.clone)
      end

      def set(var, plan)
        Error.new(
          left.set(var,plan),
          right.set(var.plan),
          item.clone)
      end
    end

  end

end

