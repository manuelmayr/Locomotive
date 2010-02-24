require 'test/unit'
require 'ripper'
require 'pp'
require 'importer'

import 'locomotive/ruby_ast/ruby_ast_node'
import 'locomotive/ruby_ast/sexp_ast_helper'
import 'locomotive/ruby_ast/sexp_to_ast'

module Locomotive

module RubyAst

module Tests

module Unit

class SExpToRubyTest < Test::Unit::TestCase

  def setup
    query = "1+1"
    @ast = SExpToAst.new(query).parse
  end

  def test_converter
    assert true    
  end

end

end

end

end

end
