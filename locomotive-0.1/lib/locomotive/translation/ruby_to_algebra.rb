include Locomotive::RelAlgAst::RelAlgFactory

module Locomotive

module Translation

class RubyToAlgebra
  extend ::Locomotive::Translation::RubyToAlgebraHelper 
  define_translate_atomic     :@int, :@float
  define_translate_binary_ops :+, :-, :*, :/,
                              :==, :<, :>, :<=, :>=


  def to_concrete_value(type, value)
    case type
      when :@float then value.to_f
      when :@int   then value.to_i
    end
  end

  def translate_array(loop, ast)
    return translate(loop, ast.left_child) if ast.has_left_child?
  end

  def translate_args_add(loop, ast)
    right = translate(loop, ast.right_child)
    return right if ast.left_child.kind == :args_new
    left = translate(loop, ast.left_child)

    project(
      rowid(
        union(
          attach(
            right,
            { :iter2 => 2 }),
          attach(
            left,
            { :iter2 => 1 })),
        :pos1,
        [ :iter ],
        { :iter => :ascending,
          :iter2  => :ascending,
          :pos => :ascending }),
      { :iter => [:iter], :pos1 => [:pos], :item => [:item] })

  end

  # translation wrapper
  # decides on the right translation rule based on the type
  def translate(loop, ast)
    translation_method = "translate_#{ast.kind}"
    if !self.respond_to?(translation_method) then
      raise NoTranslationRuleException, "No translation rule to translate #{ast.kind}"
    end
    self.send(translation_method, loop, ast)
  end

  def translate_ruby(ast)
    serialize_rel(
      niltbl,
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
