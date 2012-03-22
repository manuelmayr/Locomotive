module Locomotive

  module RelationalAlgebra

    class Distinct < Unary
      
      def initialize(op)
        super(op)
      end

      def child=(op)
        self.schema = op.schema.clone
        super(op)
      end

      def clone
        Distinct.new(
          child.clone)
      end

      def set(var,plan)
        Distinct.new(
          child.set(var,plan))
      end

      def xml_content
        content do
        end
      end
    end

  end

end

