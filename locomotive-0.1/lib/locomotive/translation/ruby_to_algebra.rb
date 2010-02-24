include Locomotive::RelAlgAst::RelAlgFactory

module Locomotive

module Translation

class RubyToAlgebra
  extend ::Locomotive::Translation::RubyToAlgebraHelper 
  define_translate_atomic     :@int, :@float
  define_translate_binary_ops :+, :-, :*, :/,
                              :==, :<, :>, :<=, :>=


  # translation wrapper
  # decides on the right translation rule based the type
  def translate(loop, ast)
    translation_method = "translate_#{ast.kind}"
    if !self.respond_to?(translation_method) then
      raise NoTranslationRuleException, "No translation rule to translate #{ast.kind}"
    end
    self.send(translation_method, loop, ast)
  end

  def translate_ruby(ast)
    serialize_rel(
      nil,
      translate(
        littbl(
          { :iter => 1 }),
        ast),
      :iter,
      :pos,
      [ :item ])
  end

end

end

end
