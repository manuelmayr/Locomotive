include Locomotive::RelationalAlgebra

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

  # factory to translate atomic nodes
  def define_translate_atomic(mtds)
    mtds.keys.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do |loop,env,ast|
        tuple = mtds[mtd]
        q = Cross.new(
              loop,
              Attach.new(
                LiteralTable.new(
                  LiteralList.new(
                    {  Item(1)  => [Atomic.new(
                                         tuple.first[ast.value],
                                         tuple.last.instance)] })),
                 AttachItem.new(Pos(1), Atomic.new(1, Nat.instance))))
        QueryInformationNode.new(
          q, PayloadList.new([ Item(1) ]), SurrogateList.new( {} ))
      end
    end
  end

  # factory to translate binary comparison functions
  def define_translate_binary_cmp(mtds)
    mtds.keys.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do |loop,env,ast|
        comp = mtds[mtd]
        q1 = translate(loop,env,ast.left_child)
        q2 = translate(loop,env,ast.right_child)
        q = Project.new(
              comp.new(
                Eqjoin.new(
                  q1.plan,
                  Project.new(
                    q2.plan,
                    ProjectList.new( { Iter(1) => [Iter(2)],
                                       Pos(1) => [Pos(2)],
                                       Item(1) => [Item(2)] } )),
                  Iter(1), Iter(2)),
                Item(3), Item(1), Item(2)),
              ProjectList.new( { Iter(1) => [Iter(1)],
                                 Pos(1) => [Pos(1)],
                                 Item(3) => [Item(1)] } ))

        QueryInformationNode.new(
          q, PayloadList.new([ Item(1) ]), SurrogateList.new( {} ))
      end
    end
  end

  # factory to translate binary ops
  def define_translate_binary_ops(mtds)
    mtds.keys.each do |mtd|
      name = to_default_name(mtd)
      define_method(name) do |loop,env,ast|
        bin = mtds[mtd].instance
        q1 = translate(loop,env,ast.left_child)
        q2 = translate(loop,env,ast.right_child)
        q = Project.new(
              Function.new(
                Eqjoin.new(
                  q1.plan,
                  Project.new(
                    q2.plan,
                    ProjectList.new( { Iter(1) => [Iter(2)],
                                       Pos(1) => [Pos(2)],
                                       Item(1) => [Item(2)] } )),
                  Iter(1), Iter(2)),
                bin,
                Item(3), [ Item(1), Item(2) ]),
              ProjectList.new( { Iter(1) => [Iter(1)],
                                 Pos(1) => [Pos(1)],
                                 Item(3) => [Item(1)] } ))

        QueryInformationNode.new(
          q, PayloadList.new([ Item(1) ]), SurrogateList.new( {} ))
      end
    end
  end

end

end

end
