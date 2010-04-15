module Locomotive

  module RelationalAlgebra

    class Nil < Leaf
      def clone
        Nil.new
      end
    end

  end

end
