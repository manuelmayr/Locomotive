require 'ripper'

module Locomotive 

module RubyAst

class SExpToAst < Ripper::SexpBuilder
  extend SExpAstHelper
  define_void_handler      :stmts_new, :string_content, :args_new
  define_atomic_handler    :int, :ident, :tstring_content, :const,
                           :float, :kw # kw is the type for boolean values
                                       # and nil
  define_unary_handler     :program, :var_field, :var_ref, :rest_param,
                           :string_embexpr, :string_literal, :array,
                           :return, :arg_paren, :paren
  define_binary_handler    :assign, :stmts_add, :method_add_block,
                           :brace_block, :string_add, :block_var, :args_add,
                           :do_block, :const_path_ref, :method_add_arg,
                           :lambda, :aref
  define_unary_op_handler  :unary
  define_binary_op_handler :binary, :call

  # following cases need special treatment
  # ripper proofs to be a bit inconsistent here

  def on_args_add_block(n1, tf)
    sexp = super(n1,tf).tap {}
    RubyAstNode.new(:args_add_block, nil, n1,
      RubyAstNode.new(if tf == true then :true else :false end))
  end

  def on_params(params1, n1, rest, params2, n3)
    ast_param_new = RubyAstNode.new(:param_new)
    ast_params = params1.inject(ast_param_new) do |p,n| 
      RubyAstNode.new(:param_add, nil, p, n)
    end if !params1.nil?

    ast_params = RubyAstNode.new(:param_add,
                         nil,
                         ast_params, rest) if !rest.nil?

    ast_params = params2.inject(ast_params) do |p,n| 
      RubyAstNode.new(:param_add, nil, p, n) 
    end if !params2.nil?

    ast_params
  end
end

end

end

