module Locomotive

  module RelationalAlgebra

    # serialize operator
    class SerializeRelation < Serialize
      include Locomotive::XML
      def_node :logical_query_plan
    
      attr_accessor :iter,
                    :pos,
                    :items
      def_sig :iter=, ConstAttribute
      def_sig :pos=, ConstAttribute
      def_sig :items=, [ConstAttribute]
    
      def initialize(side,alg,iter,pos,items)
        self.iter,
        self.pos,
        self.items = iter, pos, items
        super(side,alg)
      end
    
      def left_and_right(side,alg)
        unless alg.schema.attributes?([self.iter])
          raise CorruptedSchema,
                "Schema #{alg.schema.attributes} does not " \
                "contain all attributes of #{iter}."
        end
        unless alg.schema.attributes?([self.pos])
          raise CorruptedSchema,
                "Schema #{alg.schema.attributes} does not " \
                "contain all attributes of #{pos}."
        end
        unless alg.schema.attributes?(self.items)
          raise CorruptedSchema,
                "Schema #{alg.schema.attributes} does not " \
                "contain all attributes of #{items}."
        end
        self.schema = alg.schema.clone
        super(side,alg)
      end
    
      def xml_kind
        "serialize relation".to_sym
      end
    
      def xml_content
        pos_ = -1
        content do
          [
            column(:name => iter.to_xml, :new => false, :function => :iter),
            column(:name => pos.to_xml, :new => false, :function => :pos),
            items.collect do |it|
              column :name => it.to_xml,
                     :new => false,
                     :function => :item,
                     :position => pos_ += 1
            end.join
          ].join
        end
      end
    
      def serialize
        xml_id = 0
        xml_list = []
    
        self.traverse_strategy.clean_visited_list
        self.traverse do |op|
          op.id = xml_id += 1
          xml_list << op.to_xml
        end
#
#        # for performance reason we want to
#        # avoid the generic traverse function
#        self.visited_with_children=false
#        self.traverse do |op|
#          op.visited = false
#        end
    
        logical_query_plan :unique_names => true do
          xml_list.join
        end
      end
    
      def clone
        Serialization.new(left.clone,
                          right.clone,
                          iter.clone,
                          pos.clone,
                          items.clone)
      end
    
      def set(var,plan)
        Serialization.new(
          left.set(var,plan),
          right.set(var,plan),
          iter.clone,
          pos.clone,
          items.clone)
      end
    end
 
  end

end
