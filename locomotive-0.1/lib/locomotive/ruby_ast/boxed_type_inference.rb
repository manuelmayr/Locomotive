module Locomotive

module RubyAst

class BoxedTypeInference
  extend BoxedTypeInferenceHelper
  define_infer_atomic     :@int, :@float
  define_infer_binary_ops :+, :-, :*, :/,
                          :==, :<, :>, :<=, :>=

  def infer_type(ast)
    infer_method = "infer_#{ast.kind}".to_sym
    if !self.respond_to?(infer_method) then
      raise NoTypingRuleFoundException, "No rule to infer #{ast.kind}"
    end
    self.send(infer_method, ast)
  end

end

end

end
