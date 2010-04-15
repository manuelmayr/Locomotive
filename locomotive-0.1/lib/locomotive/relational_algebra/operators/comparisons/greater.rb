module Locomotive

  module RelationalAlgebra

    class GreaterThen < Comparison
      def xml_kind
        :gt
      end
    end

  end

end
