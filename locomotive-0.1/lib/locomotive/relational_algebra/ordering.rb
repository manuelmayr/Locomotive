module Locomotive

  module RelationalAlgebra

    # Sortdirection specifies which 
    # order a column should follow
    class SortDirection
      include Singleton

      class << self
        alias :dir :instance
      end
    
      def to_xml
        self.class.to_s.split('::').last.downcase.to_sym
      end
    
      def clone
        # singleton
        self
      end
    end

    # Sortdirection ascending
    class Ascending < SortDirection; end
    # Sortdirection descending
    class Descending < SortDirection; end
  end

end
