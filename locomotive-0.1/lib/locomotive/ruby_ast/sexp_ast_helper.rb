module Locomotive 

module RubyAst

module SExpAstHelper
  private 

  def to_default_name(sym)
    name = sym.to_s
    name = "on_" + name
    name.to_sym
  end

  public

  def define_void_handler(*mtds)
    mtds.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do
        sexp = super().tap {} 
        RubyAstNode.new(sexp[0])
      end
    end
  end

  def define_atomic_handler(*mtds)
    mtds.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do |token|
        sexp = super(token).tap {}
        atomic = RubyAstNode.new(sexp[0],
                                 sexp[1],
                                 nil,nil)
        atomic.ann_code = sexp[2]
        atomic
      end
    end
  end

  def define_unary_handler(*mtds)
    mtds.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do |unary|
        sexp = super(unary).tap {}
        RubyAstNode.new(sexp[0],
                nil,
                unary)
      end
    end
  end

  def define_binary_handler(*mtds)
    mtds.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do |left,right|
        sexp = super(left,right).tap {}
        RubyAstNode.new(sexp[0],
                nil,
                left, right)
      end
    end
  end

  def define_unary_op_handler(*mtds)
    mtds.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do |op,left|
        sexp = super(left).tap {}
        RubyAstNode.new(op,
                nil,
                left)
      end
    end
  end


  def define_binary_op_handler(*mtds)
    mtds.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do |left,operator,right|
        RubyAstNode.new(if operator == ".".to_sym then
                          :dot
                        else
                          operator
                        end,
                        nil,
                        left, right)
      end
    end
  end

end

end

end

