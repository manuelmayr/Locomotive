include Locomotive::RelationalAlgebra::Operators

module Locomotive

module Translation

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
                              :< => LessThen,
                              :> => GreaterThen, 
                              :<= => LessEqualThen,
                              :>= => GreaterEqualThen


  def translate_array(loop, env, ast)
    return nil unless ast.has_left_child?
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
    c = Item(300)
    q_0 = Attach.new(
            Project.new(
              loop,
              ProjectList.new( { Iter(1) => [Iter(1), c] })),
            AttachItem.new(Pos(1), Atomic.new(1, Nat.instance)))
    QueryInformationNode.new(
      q_0, PayloadList.new( [ c ] ), SurrogateList.new( { c => q_in } ))
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

        q_prime = Project.new(q,
                          ProjectList.new( { q_ref.name_mapping.keys.first => [Item(1)],
                                             Pos(1) => [Pos(1)],
                                             Iter(1) => [Iter(1)],
                                             Iter(2) => [Item(2)]} ))

        (q_ref.name_mapping.keys -
        [q_ref.name_mapping.keys.first]).each do |item|
          q_prime = Union.new(
                      q_prime,
                      Project.new(q,
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

  def translate_ruby(ast)
    loop = LiteralTable.new(
             LiteralList.new(
               {  Iter(1)  => [Atomic.new(
                                    1,
                                    Nat.instance)] }))
    q_in = translate(loop, {}, ast)
    
    lplans = []
    lplans <<
     RelLambda.new(
       Variable.new(1),
       SerializeRelation.new(
          Nil.new, q_in.plan,
          Iter(1), Pos(1), q_in.payload_items.to_a))
    lplans += collect_surrogates(q_in.surrogates)
    QueryPlanBundle.new(lplans)
  end

end

end

end
