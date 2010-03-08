include Locomotive::RelAlgAst::RelAlgFactory

module Locomotive

module Translation

module RubyToAlgebraHelper

  private

  def to_default_name(sym)
    name = sym.to_s
    name = "translate_" + name
    name.to_sym
  end

  public

  def define_translate_atomic(*mtds)
    mtds.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do |loop,ast|
        val = to_concrete_value(mtd, ast.value)
        cross(
          loop,
          attach(
            littbl(
              { :item => val}),
            { :pos => 1 }))
      end
    end
  end

  def define_translate_binary_ops(*mtds)
    mtds.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do |loop,ast|
        q1 = translate(loop,ast.left_child)
        q2 = translate(loop,ast.right_child)
        project(
          fun_1to1(
            eqjoin(
              q1,
              project(
                q2,
                { :iter => [:iter1], :pos => [:pos1], :item => [:item1] }),
              :iter,
              :iter1),
            ast.kind,
            :item2,
            [:item, :item1]),
          { :iter => [:iter], :item2 => [:item], :pos => [:pos] })
      end
    end
  end

end

end

end
