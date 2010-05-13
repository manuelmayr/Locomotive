module Locomotive

  module RelationalAlgebra

    class RefTbl < Leaf
      def_node :table, :properties, :keys, :key
      attr_reader :name,
                  :attributes
    
      private
    
      def get_schema
        mapping =
          { :integer => RInt.instance,
            :float   => RDec.instance,
            :string  => RStr.instance }
        id = 0
        Schema.new(
          Hash[*@attributes.collect do |attr, ty|
                  [Item.new(id += 1), [ty]]
                end.flatten_once])
      end
    
      def get_name_mapping
        id = 0
        @attributes.collect do |attr, ty|
           [ Item.new(id += 1), attr.clone ]
        end.to_hash
      end
      
      public
    
      attr_accessor :name
      def_sig :name=, String
      attr_reader :name_mapping
    
      def initialize(name, attributes)
        @name = name
        @attributes = attributes
        @name_mapping = get_name_mapping
        self.schema = get_schema
      end
    
      def xml_kind
        :ref_tbl
      end
    
      def xml_content
        content do
          table :name => name do 
            name_mapping.collect do |new,old|
              column :name => new.to_xml, :tname => old.to_xml, :type => schema[new].first.to_xml
            end.join
          end
        end
      end
    
      def clone
        RefTbl.new(name.clone)
      end
    end
    
  end

end 
