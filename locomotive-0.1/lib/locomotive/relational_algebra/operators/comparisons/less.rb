module Locomotive

  module RelationalAlgebra

    class LessThan < Comparison
      def xml_kind
        :lt
      end
    end

  end

end
