module Locomotive

  module RelationalAlgebra

    class AggrFun
      include Singleton
    
      def to_xml
        self.class.to_s.split("::").last.downcase.to_sym
      end
    
      def clone
        self
      end
    end
    
    class Count < AggrFun; end
    class Max < AggrFun; end
    class Min < AggrFun; end
    class Sum < AggrFun; end
    class Avg < AggrFun; end
    class All < AggrFun; end

  end

end
