module Locomotive

  module RelationalAlgebra

    class LessThan < Comparison

      def initialize(op, res, items)
        super(op, res, items)
        change = self.item2
        self.item2 = self.item1
        self.item1 = change
      end

      def xml_kind
        :gt
      end
    end

  end

end
