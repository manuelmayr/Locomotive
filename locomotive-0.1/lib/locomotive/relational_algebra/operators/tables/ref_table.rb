module Locomotive

  module RelationalAlgebra

    class RefTbl < Leaf
      def_node :table, :properties, :keys, :key
    
      private
    
      def columns
        @columns ||= engine.columns(name,
                                     "#{name} columns")
      end
    
      def keys
        @keys = columns.select do |col|
                  col.primary
                end
      end
    
      def get_schema
        mapping =
          { :integer => RInt.instance,
            :float   => RDec.instance,
            :string  => RStr.instance }
        id = 0
        Schema.new(
          Hash[*columns.collect do |col|
                  [Item(id += 1), [mapping[col.type]]]
                end.flatten_once])
      end
    
      def get_name_mapping
        id = 0
        columns.collect do |col|
           [ Item(id += 1), Attribute(col.name) ]
         end.to_hash
      end
      
      public
    
      cattr_accessor :engine
      attr_reader :engine
      attr_accessor :name
      def_sig :name=, String
      attr_reader :name_mapping
    
      def initialize(name, engine = nil)
        @engine = engine || Table.engine
        @name = name
        @name_mapping = get_name_mapping
        self.schema = get_schema
      end
    
      def reset
        @columns = nil
        @keys = nil
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
        RefTbl.new(name.clone, engine)
      end
    end
    
  end

end 
