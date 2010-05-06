module Locomotive

  module RelationalAlgebra

    #
    # The Schema contains the attributes
    # and its associated types.
    # Each operator of the relational algebra
    # contains a schema.
    #
    class Schema
      include Locomotive::XML
      def_node :_schema_, :col
    
      protected
    
      attr_accessor :schema
      def_sig :schema=, { Attribute => [RType] }
      
      # check if there are duplicates in the schemas
      def duplicates?(schema)
        (self.attributes + schema.attributes).length >
        (self.attributes + schema.attributes).uniq.length
      end
      def_sig :duplicates?, Schema
    
      public
    
      def initialize(hash)
        self.schema = hash
      end
    
      def attributes
        schema.keys
      end
    
      def attributes?(attributes)
        attributes.all? { |attr| self.attributes.member? attr }
      end
      def_sig :attributes?, [Attribute]
    
      # merges two schemas, given that there are
      # no duplicate keys
      def +(schm)
        if duplicates?(schm)
          raise Duplicates,
                "Found duplicates in #{self.attributes} " \
                "and #{schm.attributes}."
        end
        # create a new schema
        Schema.new(schema.merge(schm.schema))
      end
      def_sig :+, Schema
    
      def []=(attr,types)
        schema[attr] = types
      end
      def_sig :[]=, Attribute, [RType]
    
      def method_missing(mtd, *params, &block)
        if schema.respond_to? mtd
          schema.send(mtd, *params, &block)
        else
          super.method_missing(mtd, *params, &block)
        end
      end
    
      def to_xml
        _schema_ do
          self.schema.collect do |attr,types|
            col :name => attr.to_xml,
                :type => types.collect { |ty| ty.to_xml }.join(",")
          end.join
        end
      end
    
      def clone
        Schema.new( self.schema.clone )
      end
    end

  end

end
