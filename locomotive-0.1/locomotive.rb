require "active_record"


require 'lib/locomotive/ast_helpers/annotations'
require 'lib/locomotive/utils/xml'
require 'lib/locomotive/ast_helpers/ast'
require 'lib/locomotive/ast_helpers/ast_traversal'
require 'lib/locomotive/misc/type_check'
require 'lib/locomotive/ruby_ast/types'
require 'lib/locomotive/ruby_ast/ast_exceptions'
require 'lib/locomotive/translation/translation_exceptions'
require 'lib/locomotive/rel_alg_ast/rel_alg_exceptions'
require 'lib/locomotive/rel_alg_ast/types'
require 'lib/locomotive/rel_alg_ast/attributes'
require 'lib/locomotive/engine/sql/engine'
require 'lib/locomotive/misc/array_ext'
require 'lib/locomotive/misc/hash_ext'

require 'lib/locomotive/rel_alg_ast/rel_alg_ast_node'
# <= annotations, ast
require 'lib/locomotive/rel_alg_ast/rel_alg_factory'
# <= rel_alg_ast_node
require 'lib/locomotive/rel_alg_ast/table'
# <= rel_alg_ast_node
require 'lib/locomotive/ruby_ast/ruby_ast_node'
# <= annotations, ast
require 'lib/locomotive/ruby_ast/sexp_ast_helper'
require 'lib/locomotive/rel_alg_ast/rel_alg_ops'
# <= ruby_ast_node
require 'lib/locomotive/ruby_ast/sexp_to_ast'
# <= ruby_ast_node
require 'lib/locomotive/ruby_ast/boxed_type_inference_helper'
# <= ruby_ast_node
require 'lib/locomotive/ruby_ast/boxed_type_inference'
# <= ruby_ast_node
require 'lib/locomotive/utils/ast2dot'
# <= ruby_ast_node
require 'lib/locomotive/utils/relalg2xml'
# <= ruby_ast_node
require 'lib/locomotive/translation/ruby_to_algebra_helper'
require 'lib/locomotive/translation/ruby_to_algebra'
# <= ruby_ast_node, rel_alg_ast_node

Locomotive::RelAlgAst::Table.engine = Locomotive::Engines::Sql::Engine.new(ActiveRecord::Base)
Locomotive::RelationalAlgebra::Operators::RefTbl.engine = Locomotive::Engines::Sql::Engine.new(ActiveRecord::Base)
