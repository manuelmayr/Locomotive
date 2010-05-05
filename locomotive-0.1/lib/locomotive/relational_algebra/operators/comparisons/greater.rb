module Locomotive

  module RelationalAlgebra

    class GreaterThan < Comparison
      def xml_kind
        :gt
      end
    end

  end

end
