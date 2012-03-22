module Locomotive

  module RelationalAlgebra

    class LessEqualThan < Comparison
      def xml_kind
        :lteq
      end
    end

  end

end
