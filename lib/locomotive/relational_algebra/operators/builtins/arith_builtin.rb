module Locomotive

  module RelationalAlgebra

    class Addition < Fun
      def to_xml
        :add
      end
    end

    class Subtraction < Fun
      def to_xml
        :subtract
      end
    end

    class Multiplication < Fun
      def to_xml
        :multiply
      end
    end

    class Division < Fun
      def to_xml
        :divide
      end
    end

    class Contains < Fun
      def to_xml
        :contains
      end
    end

  end

end
