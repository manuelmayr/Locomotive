include Locomotive::RelationalAlgebra

module Locomotive

module Translation

class Environment
  extend Locomotive::TypeChecking::Signature
  attr_accessor :methods
  def_sig :methods=, { Symbol => RelLambda }

  def initialize(methods)
    self.methods = methods
  end
end

ARRAY_ENV = { :count => RelLambda.new(
                          Variable.new(1),
                          Attach.new(
                            Aggr.new(
                              Variable.new(1, Item(1)),
                              Count.instance,
                              Item(1),
                              [ Iter(1) ]),
                            AttachItem.new(Pos(1), Atomic.new(1, Nat.instance)))),
              :at => RelLambda.new(
                       Variable.new(1),
                       RelLambda.new(
                         Variable.new(2),
                         Project.new(
                           Eqjoin.new(
                             LiteralTable.new(
                               LiteralList.new( { Pos(2) => [Atomic.new(1,Nat.instance)] } )),
                             Variable.new(2, Item(1)),
                             Pos(2), Pos(1)),
                           ProjectList.new( { Iter(1) => [Iter(1)],
                                              Pos(1)  => [Pos(1)],
                                              Item(1) => [Item(1)] } )))) }


class RubyToAlgebra
  extend Locomotive::Translation::RubyToAlgebraHelper 
  define_translate_atomic     :@int => [->(s) { Integer(s) },Int],
                              :@float => [->(s) { Float(s) },Dec],
                              :@tstring_content => [->(s) { String(s) },Str]
  define_translate_binary_ops :+ => Addition,
                              :- => Subtraction,
                              :* => Multiplication,
                              :/ => Division
  define_translate_binary_cmp :== => Equal,
                              :< => LessThan,
                              :> => GreaterThan, 
                              :<= => LessEqualThan,
                              :>= => GreaterEqualThan

  def join(q_in)
    # join all surrogate tables
    items = []
#    resolved = q_in.surrogates.inject(q_in.plan) do |eqjoin,key_plan|
#                 items << [Item(2), [key_plan.first]]
#                 Project.new(
#                   Eqjoin.new(
#                     eqjoin,
#                     Project.new(
#                       key_plan.last,
#                       ProjectList.new({ Iter(1) => [Iter(2)],
#                                         Pos(1)  => [Pos(2)],
#                                         Item(1) => [Item(2)] })),
#                     key_plan.first,
#                     Iter(1)),
#                   ProjectList.new({Iter(1) => [Iter(1)],
#                                    Pos(1)  => [Pos(1)]}.merge(
#                                      items.to_hash))
#               end
#
#    
  end

  def translate_array(loop, env, ast)
    return nil unless ast.has_left_child?
    q_in = translate(loop, env, ast.left_child)
    q_in.methods = ARRAY_ENV
    q_in
  end

  def translate_args_add_block(loop, env, ast)
    return nil unless ast.has_left_child?
    # FIXME right child has to be translated (lambda)
    translate(loop, env, ast.left_child)
  end

  def translate_args_add(loop, env, ast)
    # translate left and right tree to their loop
    # lifted encodings
    q_e1 = box(loop,translate(loop, env, ast.right_child))
    return q_e1 if ast.left_child.kind == :args_new

    # in ruby there are no tuples so we box everything
    q_e2 = translate(loop, env, ast.left_child)

    # calculate new surrogate keys since we operate on arrays
    q = RowId.new(
          Union.new(
            Attach.new(
              q_e1.plan,
              AttachItem.new(Iter(2), Atomic.new(2, Nat.instance))),
            Attach.new(
              q_e2.plan,
              AttachItem.new(Iter(2), Atomic.new(1, Nat.instance)))),
          Item(2))

    # calculate new positions
    q_prime = Project.new(
                Rank.new(
                  q,
                  Pos(2),
                  SortList.new({ Iter(2) => Ascending.instance,
                                 Pos(1) => Ascending.instance })),
                ProjectList.new( { Iter(1) => [Iter(1)],
                                   Pos(1)  => [Pos(1)] }.merge(
                                   Hash[*(q_e1.payload_items.to_a -
                                          q_e1.surrogates.keys).collect do |itm|
                                            [itm, [itm]]
                                          end.flatten_once]).merge(
                                   Item(2) => q_e1.surrogates.keys)))

    # append inner tables
    itbl_prime = q_e1.surrogates.itapp(q,q_e2.surrogates)

    QueryInformationNode.new(
      q_prime, q_e1.payload_items, itbl_prime)
  end

  def box(loop, q_in)
    c = Item(1)
    q_0 = Attach.new(
            Project.new(
              loop,
              ProjectList.new( { Iter(1) => [Iter(1), c] })),
            AttachItem.new(Pos(1), Atomic.new(1, Nat.instance)))
    QueryInformationNode.new(
      q_0, PayloadList.new( [ c ] ), SurrogateList.new( { c => q_in } ))
  end

  def unbox(q_in)
    unless q_in.payload_items.length == 1 and
           q_in.surrogates.length == 1 and
           q_in_new = q_in.surrogates[q_in.payload_items.first]
      raise StandardError, "unbox"
    end

    q_in_new
  end

  def translate_method_add_arg(loop, env, ast)
    q1_in = translate(loop, env, ast.left_child)
    q2_in = translate(loop, env, ast.right_child)

    # get the method and argument from the left translation
    method = q1_in.plan
    unless method.class == RelLambda
      raise StandardError, "#{q1_in.class} is not a method"
    end

    # currently we are dealing only with arrays => Item(1)
    # order the array for convenient access
    arg = Project.new(
            RowNum.new(
              Project.new(
                Eqjoin.new(
                  q2_in.plan,
                  Project.new(
                    q2_in.surrogates[q2_in.payload_items.first].plan,
                    ProjectList.new( { Iter(1) => [Iter(2)],
                                       Pos(1)  => [Pos(2)],
                                       Item(1) => [Item(2)] })),
                  Item(1), Iter(2)),
                ProjectList.new( { Iter(1) => [Iter(1)],
                                   Pos(1) => [Pos(1)],
                                   Item(2) => [Item(1)] } )),
              Pos(2),
              [ Iter(1) ],
              SortList.new( { Pos(1) => Ascending.instance } )),
            ProjectList.new( { Iter(1) => [Iter(1)],
                               Pos(2) => [Pos(1)],
                               Item(1) => [Item(1)] } ))

   # apply the argument
   method = method.apply(arg)

   QueryInformationNode.new(
     method,
     PayloadList.new([ Item(1) ]),
     SurrogateList.new( {} ))
  end

  def translate_dot(loop, env, ast)
    q1_in = translate(loop, env, ast.left_child)
     
    plan = q1_in.methods[ast.right_child.value.to_sym]

    if plan.nil?
      raise StandardError, "Method missing"
    end

    QueryInformationNode.new(
      plan.apply(q1_in.plan),
      PayloadList.new([ Item(1) ]),
      q1_in.surrogates)
  end

  def translate_var_ref(loop, env, ast)
    case ast.left_child.kind
      when :@const then  
        # calculate the surrogates
        q = RowId.new(
              RowId.new(
                Cross.new(
                  loop,
                  q_ref = RefTbl.new(ast.left_child.value)),
                Iter(2)),
              Pos(1))

        q_prime_ = Project.new(
                     q,
                     ProjectList.new( { q_ref.name_mapping.keys.first => [Item(1)],
                                        Pos(1) => [Pos(1)],
                                        Iter(1) => [Iter(1)],
                                        Iter(2) => [Item(2)]} ))

        q_prime = (q_ref.name_mapping.keys -
                   [q_ref.name_mapping.keys.first]).inject(q_prime_) do |q_last,item|
                     q_prime = Union.new(
                                 q_last,
                                 Project.new(
                                     q,
                                     ProjectList.new( { item => [Item(1)],
                                                        Pos(1) => [Pos(1)],
                                                        Iter(1) => [Iter(1)],
                                                        Iter(2) => [Item(2)] })))
                   end

        q_outer = Project.new(
                     q_prime,
                     ProjectList.new( { Item(2) => [Item(1)],
                                        Pos(1) => [Pos(1)],
                                        Iter(1) => [Iter(1)] } ))
        q_inner = Project.new(
                     q_prime,
                     ProjectList.new( { Item(2) => [Iter(1)],
                                        Pos(1) => [Pos(1)],
                                        Item(1) => [Item(1)] } ))

        q_in = QueryInformationNode.new(
                 q_outer, 
                 PayloadList.new([ Item(1) ]), 
                 SurrogateList.new( { Item(1) => QueryInformationNode.new(
                                                   q_inner, 
                                                   PayloadList.new([ Item(1) ]),
                                                   SurrogateList.new({})) })) 

        box(loop,q_in)
      else q = nil 
    end
  end

  # translation wrapper
  # decides on the right translation rule based on the type
  def translate(loop, env, ast)
    translation_method = "translate_#{ast.kind}"
    if !self.respond_to?(translation_method) then
      raise NoTranslationRuleException, "No translation rule to translate #{ast.kind}"
    end
    self.send(translation_method, loop, env, ast)
  end

  def collect_surrogates(surr)
    lplans = []
    surr.each do |attr,q_in|
      lplans << SerializeRelation.new(
                  Nil.new, q_in.plan,
                  Iter(1), Pos(1), q_in.payload_items.to_a)
      lplans += collect_surrogates(q_in.surrogates)
    end
    lplans
  end

  def translate_arg_paren(loop, env, ast)
    translate(loop, env, ast.left_child)
  end

  def translate_ruby(ast)
    loop = LiteralTable.new(
             LiteralList.new(
               {  Iter(1)  => [Atomic.new(
                                    1,
                                    Nat.instance)] }))
    q_in = translate(loop, {}, ast)
    
    lplans = []
    lplans <<
       SerializeRelation.new(
          Nil.new, q_in.plan,
          Iter(1), Pos(1), q_in.payload_items.to_a)
    lplans += collect_surrogates(q_in.surrogates)
    QueryPlanBundle.new(lplans)
  end

end

end

end
