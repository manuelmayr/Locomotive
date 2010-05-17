module Locomotive

  module RelationalAlgebra
  
    # Represents a Relational Algebra node
    # Such a node has
    #  * the behaviour of a composite pattern
    #  * and node specific annotations
    class RelAlgAstNode
      include AstHelpers::AstNode
      include AstHelpers::Annotations

      [:project, :attach,
       :or, :and,
       :aggr,
       :select,
       :difference, :union,
       :cross, :equi_join, :theta_join,
       :equal, :greater_than,
       :less_than, :less_equal_than,
       :row_num, :row_id, :rank, :row_rank,
       :cast,
       :serialize_relation].each do |op|
        define_method(op) do |*args|
          ::Locomotive::RelationalAlgebra.const_get(op.classify).new(self, *args)
        end
      end

      [:addition, :subtraction,
       :multiplication, :division].each do |meth|
        define_method(meth) do |*args|
          Function.new(self,
                       ::Locomotive::RelationalAlgebra.const_get(meth.classify).instance,
                       *args)
        end
      end

      [:max, :min, :count].each do |meth|
        define_method(meth) do |*args|
          Aggr.new(self,
                   ::Locomotive::RelationalAlgebra.const_get(meth.classify).instance,
                   *args)
        end
      end
    end
  
  end

end

