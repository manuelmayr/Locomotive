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

  end

end
