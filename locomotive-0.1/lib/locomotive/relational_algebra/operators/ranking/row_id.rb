module Locomotive

  module RelationalAlgebra

    class RowId < Numbering
      def initialize(op, res)
        super(op,res,{})
      end
    
      def clone
        RowId.new(child.clone,
                    res.clone)
      end
    
      def set(var,plan)
        RowId.new(
          child.set(var,plan),
          res.clone)
      end
    end

  end

end
