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
      print name
      define_method(name) do |loop,ast|
        cross(
          loop,
          attach(
            littbl(
              { :item => ast.value}),
            { :pos => 1 }))
      end
    end
  end

  def define_translate_binary_ops(*mtds)
    mtds.each do |mtd|
      name = to_default_name(mtd)
      print name
      define_method(name) do |loop,ast|
        q1 = translate(loop,ast.left_child)
        q2 = translate(loop,ast.right_child)
        project(
          fun_1to1(
            eqjoin(
              q1,
              project(
                q2,
                { :iter => [:iter_1], :pos => [:pos_1], :item => [:item_1] }),
              :iter,
              :iter_1),
            ast.kind,
            :item,
            [:item, :item_1]),
          { :iter => :iter, :item => :item, :pos => :pos })
      end
    end
  end

end

end

end
