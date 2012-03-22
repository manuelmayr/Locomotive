module Locomotive

  module RelationalAlgebra

    class Fun
      include Singleton
    
      def to_xml
        self.class.to_s.split("::").last.downcase
      end
    
      def clone
        #singleton
        self
      end
    end
    
  end

end 
