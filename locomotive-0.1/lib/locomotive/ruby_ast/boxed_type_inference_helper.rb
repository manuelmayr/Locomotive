module Locomotive

module RubyAst

# Helper Functions to specify the
# type-inference for boxing and unboxing
module BoxedTypeInferenceHelper

  private

  def to_default_name(sym)
    name = sym.to_s
    name = "infer_" + name
    name.to_sym
  end

  public

  def define_infer_atomic(*mtds)
    mtds.each do |mtd|
      name = to_default_name(mtd) 
      define_method(name) do |ast|
        # we expect a kind with type mtd
        if ast.kind != mtd then
          raise BoxedTypeInferenceException,
                "#{mtd} expected, found #{ast.kind}"
        end

        Row.new
      end
    end
  end

  def define_infer_binary_ops(*mtds)
    mtds.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do |ast|
        if ast.kind != mtd then
          raise BoxedTypeInferenceException, 
                "#{mtd} expected, found #{ast.kind}"
        end

        Row.new
      end
    end
  end

end

end

end
