require "pp"

module Locomotive

module RelAlgAst

module RelAlgFactory
  private

  class << self
    def define_ranking_operators(*mtds)
      mtds.each do |mtd|
        name = mtd
        define_method(name) do |expr, res, part, order|
          abort_when_not_ast_nodes expr
          abort_when_corrupted_schema(part + order.keys, expr.ann_schema)
          abort_when_duplicates([res] + expr.ann_schema.keys)
      
          rank = RelAlgAstNode.new(
                      name,
                      nil,
                      expr)
      
          rank.ann_res = res
          rank.ann_order = order
          rank.ann_part  = part
      
          rank.ann_schema = {}.merge(expr.ann_schema).merge({ res => [:int] })
          
          rank
        end
      end
    end
  end

  def type_to_pf_type(type)
    # === doesn't work with Classes
    case type.class.to_s
      when "Float"  then "dec"
      when "Fixnum" then "int"
    end
  end
 
    
  def duplicates?(array)
    array.length > array.uniq.length
  end

  def copy_schema(items, schema)
    cschema = {}
    items.each do |item|
      cschema[item] = schema[item]
    end
    cschema
  end

  def ast_nodes?(*nodes)
    nodes.all? { |node| node.class == RelAlgAstNode }
  end

  def abort_when_not_ast_nodes(*nodes)
    if !ast_nodes? *nodes then
      raise CorruptedSchemaException, "Not Ast nodes"
    end
  end

  def abort_when_duplicates(array)
    if duplicates? array
      raise StandardError, "Duplicates found"
    end
  end

  def corrupted_schema?(items, schema)
    !items.all? { |item| schema.has_key? item }
  end

  def abort_when_corrupted_schema(items, schema)
    if corrupted_schema? items, schema then
      raise CorruptedSchemaException, "Corrupted Schema #{items} vs. #{schema}"
    end
  end

  public 

  define_ranking_operators :rank, :rowid

  # the proj_items list has the following structure
  # { :item1 => [:item1], :item2 => [:item3, :item4] }
  def project(expr, proj_items)
    # sanity checks
    abort_when_not_ast_nodes    expr
    abort_when_duplicates       proj_items.values.flatten
    abort_when_corrupted_schema proj_items.keys,
                                expr.ann_schema

    proj = RelAlgAstNode.new(
            :project,
            nil,
            expr)
    # set the project items
    proj.ann_items = proj_items
    
    # calculate a new schema
    new_schema = {}
    proj.ann_items.keys.each do |item|
      proj.ann_items[item].each do |newitem|
        new_schema[newitem] = expr.ann_schema[item]
      end
    end
    proj.ann_schema = new_schema
    
    proj
  end

  def cross(left_expr, right_expr)
    # sanity checks 
    abort_when_not_ast_nodes left_expr, right_expr
    abort_when_duplicates    left_expr.ann_schema.keys +
                             right_expr.ann_schema.keys
   
    cross = RelAlgAstNode.new(
              :cross,
              nil,
              left_expr,
              right_expr)
    cross.ann_schema = left_expr.ann_schema.merge(
                         right_expr.ann_schema)
    cross
  end

  def eqjoin(left_expr, right_expr, col1, col2)
    # sanity checks
    # check if the join columns are in 
    abort_when_not_ast_nodes    left_expr, right_expr
    abort_when_duplicates       left_expr.ann_schema.keys +
                                right_expr.ann_schema.keys
    abort_when_corrupted_schema [col1], left_expr.ann_schema
    abort_when_corrupted_schema [col2], right_expr.ann_schema
    
    eqjoin = RelAlgAstNode.new(
               :eqjoin,
               nil,
               left_expr,
               right_expr)

    eqjoin.ann_col1 = col1
    eqjoin.ann_col2 = col2

    eqjoin.ann_schema = left_expr.ann_schema.merge right_expr.ann_schema 
    eqjoin
  end

  # attach_vals = { :item => 2, :item2 => 5 }
  # attach currently supports only one value 
  def attach(expr, attach_vals)
    # sanity checks
    abort_when_not_ast_nodes expr
    abort_when_duplicates expr.ann_schema.keys + attach_vals.keys

    attach = RelAlgAstNode.new(
               :attach,
               attach_vals,
               expr)
    # FIXME: we need a type here
    attach.ann_schema = {}.merge(expr.ann_schema)
    attach_vals.each_key do |key|
      attach.ann_schema[key] = [type_to_pf_type(attach_vals[key])]
    end
    attach
  end

  def niltbl
    niltbl = RelAlgAstNode.new(:nil)
    niltbl.ann_schema = {}
    niltbl
  end

 
  # values = { :col1 => val1, ..., :coln => valn }
  def littbl(values)
    # sanity checks
    abort_when_duplicates values.keys

    littbl = RelAlgAstNode.new(
               :table)
    littbl.ann_values = values
    littbl.ann_schema = {}
    values.each_key do |key|
      littbl.ann_schema[key] = [type_to_pf_type(values[key])]
    end
    littbl
  end

  def fun_1to1(expr, kind, res, columns)
    # sanity checks
    abort_when_not_ast_nodes expr
    abort_when_duplicates(expr.ann_schema.keys - columns + [res])
    abort_when_corrupted_schema columns, expr.ann_schema

    raise StandardError, 'columns > 2' if columns.length > 2
    raise StandardError, "operands have to be of" \
                         " the same type (op1(#{expr.ann_schema[columns.first]})" \
                         " vs. op2(#{expr.ann_schema[columns.last]})" if expr.ann_schema[columns.first] !=
                                                                         expr.ann_schema[columns.last]

    fun = RelAlgAstNode.new(
            :fun,
            nil,
            expr)

    fun.ann_fun_kind = kind
    fun.ann_operands = columns
    fun.ann_result = res
    fun.ann_schema = copy_schema (expr.ann_schema.keys - columns), expr.ann_schema
    
    fun.ann_schema[res] = expr.ann_schema[columns.first]
                            
    fun
  end

  def union(expr1, expr2)
    # sanity checks
    abort_when_not_ast_nodes expr1, expr2
    #raise StandardError, "schemas are not equal (#{expr1.ann_schema}" \
    #                     " vs. #{expr2.ann_schema})" if expr1.ann_schema.to_a.sort.map { |el| [el.first,el.last.sort] } !=
    #                                                    expr2.ann_schema.to_a.sort.map { |el| [el.first,el.last.sort] }
    union = RelAlgAstNode.new(
              :union,
              nil,
              expr1,
              expr2)

    union.ann_schema = {}.merge expr1.ann_schema

    union
  end

  def serialize_rel(side, alg, iter, pos, items)
    # sanity checks
    abort_when_not_ast_nodes alg
    abort_when_corrupted_schema [iter,pos] + items, alg.ann_schema

    ser = RelAlgAstNode.new(
            :serialize_rel,
            nil,
            side,
            alg)
    
    ser.ann_iter = iter
    ser.ann_pos  = pos
    ser.ann_items = items

    ser.ann_schema = {}.merge alg.ann_schema 
    ser            
  end
end

end

end
