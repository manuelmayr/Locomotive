module Locomotive

  module RelationalAlgebra

    class Aggr < Unary
      def_node :column, :aggregate
    
      attr_accessor :item, :part_list, :aggr_kind
      def_sig :aggr_kind=, AggrFun
      def_sig :part_list=, [Attribute]
      def_sig :item=, Attribute
    
      def initialize(op, aggr_kind, item, part)
        self.item = item
        self.aggr_kind = aggr_kind
        self.part_list = part
        super(op)
      end
    
      def child=(op)
        unless op.schema.attributes?(part_list)
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{part_list}."
        end
        unless op.schema.attributes?([item])
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{item}."
        end
        self.schema = Schema.new( { self.item => [RNat.instance] }.merge(
                                 Hash[*part_list.collect do |p|
                                         [p, op.schema[p]]
                                       end.flatten_once]))
                              
        super(op)
      end
    
      def xml_content
        content do
          part_list.collect do |part|
            column :name => part.to_xml, :function => :partition, :new => false
          end.join + 
          (aggregate :kind => aggr_kind.to_xml do
            column :name => item.to_xml, :new => true
          end)
        end
      end
    
      def clone
        Aggr.new(
          child.clone,
          aggr_kind.clone,
          item.clone,
          part_list.clone)
      end
    
      def set(var,plan)
        Aggr.new(
          child.set(var,plan),
          aggr_kind.clone,
          item.clone,
          part_list.clone)
      end
    end

  end

end
