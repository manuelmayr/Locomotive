module Locomotive

  module RelationalAlgebra

    class LiteralList
      include Locomotive::XML
      def_node :column
    
      protected
    
      attr_accessor :literal_list
      def_sig :literal_list=, { ConstAttribute => [RAtomic] }
      
    
      public
      delegate :[],
               :collect,
               :to_a,
               :to => :literal_list
    
      def initialize(hash)
        self.literal_list = hash
      end
    
      def attributes
        literal_list.keys
      end
    
      def to_xml
        literal_list.collect do |attr,atomary|
          column :name => attr.to_xml, :new => true do 
            atomary.collect do |atom|
              atom.to_xml
            end.join
          end
        end.join
      end
    
      def clone
        LiteralList.new( literal_list.clone )
      end
    end
    
    class LiteralTable < Leaf
      attr_reader :lit_list
    
      def lit_list=(llist)
        s = Hash[ *llist.collect do |attr, types|
                           [attr,types.collect { |a| a.type }.uniq]
                         end.flatten_once ]
        self.schema = Schema.new(s)
        @lit_list = llist
      end

      def to_literal_list(llist)
        case
          when Hash === llist then
            LiteralList.new(llist)
          when LiteralList === llist then
            llist
        end
      end
      private :to_literal_list


      def_sig :lit_list=, LiteralList
      private :lit_list

    
      def initialize(llist)
        self.lit_list = to_literal_list llist
      end
    
      def xml_kind
        :table
      end
    
      def xml_content
        content do
          lit_list.to_xml
        end
      end
    
      def clone
        LiteralTable.new( lit_list.clone )
      end
    end

    def LiteralTable(values)
      LiteralTable.new(values)
    end
     
  end

end 
