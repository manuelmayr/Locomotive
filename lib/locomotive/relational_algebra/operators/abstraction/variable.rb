module Locomotive

  module RelationalAlgebra

    class Variable < Leaf
    
      class << self
        attr_accessor :id_pool
        
        def new_variable(*items)
          Variable.id_pool ||= [0]
          new_id = Variable.id_pool.max + 1
          Variable.id_pool << new_id
          Variable.new(new_id, *items)
        end
      end
    
      attr_accessor :id, :items
      def_sig :id=, Integer
      def_sig :items=, [GenericAttribute]
      def_node :variable
    
    
      def initialize(id, *items)
        self.id,
        self.items = id, items
        Variable.id_pool << self.id
        self.schema = Schema.new({ Iter.new(1) => [RNat.type],
                                   Pos.new(1) => [RNat.type] }.merge(
                                     Hash[*items.collect do |it|
                                             [it, [RNat.instance]]
                                           end.flatten_once]) )
      end
    
      def clone
        Variable.new(id, *items.clone)
      end
    
      def xml_content
        content do
          variable :name => id
        end
      end
    
      def ==(other)
        other.class == Variable and
        other.id == self.id
      end
    
      def set(var,plan)
        if var == self
          plan.clone
        else
          self.clone
        end
      end
    
      def free
        [ self.clone ]
      end
    end
    
  end

end 
