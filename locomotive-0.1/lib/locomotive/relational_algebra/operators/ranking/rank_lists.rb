module Locomotive

  module RelationalAlgebra

    class SortList
      include Locomotive::XML
      def_node :column
    
      private
    
      attr_accessor :sort_list
      def_sig :sort_list=, { Attribute => SortDirection }
      
      public
      delegate :[],
               :to_a,
               :to => :sort_list
    
      def initialize(hash)
        self.sort_list = hash
      end
    
      def attributes
        sort_list.keys
      end
    
      def to_xml
        pos = -1
        sort_list.collect do |attr, dir|
          column :name => attr.to_xml,
                 :function => :sort,
                 :position => pos += 1,
                 :direction => dir.to_xml,
                 :new => false
        end.join
      end
    
      def clone
         SortList.new( sort_list.clone )
      end
    end
    
  end

end 
