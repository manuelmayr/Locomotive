module Locomotive

  module RelationalAlgebra

    class Equal < Comparison;
      def xml_kind
        :eq
      end
    end

  end

end
