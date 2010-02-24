require "pp"

module Locomotive

module RelAlgAst

module RelAlgFactory
  private
    
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
      raise DuplicateException, "Duplicates found"
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
    # copy the schema
    proj.ann_schema = copy_schema proj.ann_items.values.flatten,
                                  expr.ann_schema
    
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
               :join,
               nil,
               left_expr,
               right_expr)

    eqjoin.ann_col1 = col1
    eqjoin.ann_col2 = col2

    eqjoin.ann_schema = left_expr.ann_schema.merge right_expr.ann_schema 
    eqjoin
  end

  # attach_vals = { :item => 2, :item2 => 5 }
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
      attach.ann_schema[key] = [:integer]
    end
    attach
  end

  def littbl(values)
    # sanity checks
    abort_when_duplicates values.keys

    littbl = RelAlgAstNode.new(
               :littbl)
    littbl.ann_values = values
    littbl.ann_schema = {}
    values.each_key do |key|
      littbl.ann_schema[key] = [:integer]
    end
    littbl
  end

  def fun_1to1(expr, kind, res, columns)
    # sanity checks
    abort_when_not_ast_nodes expr
    abort_when_duplicates(expr.ann_schema.keys - columns + [res])
    abort_when_corrupted_schema columns, expr.ann_schema

    raise StandardError, 'columns > 2' if columns.length > 2

    fun = RelAlgAstNode.new(
            :fun_1to1,
            nil,
            expr)

    fun.ann_fun_kind = kind
    fun.ann_schema =  copy_schema (expr.ann_schema.keys - columns), expr.ann_schema
    fun.ann_schema[res] = [:integer]
    fun
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
