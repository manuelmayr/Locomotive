# -*- encoding: utf-8 -*-
require "rake"

Gem::Specification.new do |s|
  s.name = "locomotive"
  s.version = "0.0.1"

  s.author = "Manuel Mayr"
  s.email = "mayr@informatik.uni-tuebingen.de"
  s.homepage = "http://www-db.informatik.uni-tuebingen.de/research/pathfinder"
  s.description = %q{Ruby representation of the Pathfinder-Algebra
                     (http://www-db.informatik.uni-tuebingen.de/research/pathfinder).\n
                     
                     Taking an algebraic plan in XML, Pathfinder is able to generate
                     code for various database systems (SQL-99 conformant, MonetDB,
                     X100, ...). In order to generate efficient target code it also
                     does heavy optimization on the input plans.}
  s.platform = Gem::Platform::RUBY
  s.summary = ""
  s.files = [ "lib/locomotive.rb",
              "lib/locomotive/misc.rb",
              "lib/locomotive/misc/type_check.rb",
              "lib/locomotive/core_extensions.rb",
              "lib/locomotive/core_extensions/class.rb",
              "lib/locomotive/core_extensions/module.rb",
              "lib/locomotive/core_extensions/array.rb",
              "lib/locomotive/core_extensions/hash.rb",
              "lib/locomotive/core_extensions/inflector.rb",
              "lib/locomotive/core_extensions/symbol.rb",
              "lib/locomotive/relational_algebra.rb",
              "lib/locomotive/relational_algebra/attributes.rb",
              "lib/locomotive/relational_algebra/operators.rb",
              "lib/locomotive/relational_algebra/operators/abstraction.rb",
              "lib/locomotive/relational_algebra/operators/abstraction/lambda.rb",
              "lib/locomotive/relational_algebra/operators/abstraction/variable.rb",
              "lib/locomotive/relational_algebra/operators/aggregation.rb",
              "lib/locomotive/relational_algebra/operators/aggregation/aggr_builtin.rb",
              "lib/locomotive/relational_algebra/operators/aggregation/aggregation.rb",
              "lib/locomotive/relational_algebra/operators/basic_operators.rb",
              "lib/locomotive/relational_algebra/operators/boolean.rb",
              "lib/locomotive/relational_algebra/operators/boolean/and.rb",
              "lib/locomotive/relational_algebra/operators/boolean/basic_boolean.rb",
              "lib/locomotive/relational_algebra/operators/boolean/or.rb",
              "lib/locomotive/relational_algebra/operators/boolean/not.rb",
              "lib/locomotive/relational_algebra/operators/builtins.rb",
              "lib/locomotive/relational_algebra/operators/builtins/arith_builtin.rb",
              "lib/locomotive/relational_algebra/operators/builtins/basic_builtin.rb",
              "lib/locomotive/relational_algebra/operators/builtins/function.rb",
              "lib/locomotive/relational_algebra/operators/comparisons.rb",
              "lib/locomotive/relational_algebra/operators/comparisons/basic_comparison.rb",
              "lib/locomotive/relational_algebra/operators/comparisons/equal.rb",
              "lib/locomotive/relational_algebra/operators/comparisons/greater.rb",
              "lib/locomotive/relational_algebra/operators/comparisons/greater_equal.rb",
              "lib/locomotive/relational_algebra/operators/comparisons/less.rb",
              "lib/locomotive/relational_algebra/operators/comparisons/less_equal.rb",
              "lib/locomotive/relational_algebra/operators/filter.rb",
              "lib/locomotive/relational_algebra/operators/filter/select.rb",
              "lib/locomotive/relational_algebra/operators/join.rb",
              "lib/locomotive/relational_algebra/operators/join/basic_join.rb",
              "lib/locomotive/relational_algebra/operators/join/cross.rb",
              "lib/locomotive/relational_algebra/operators/join/equi_join.rb",
              "lib/locomotive/relational_algebra/operators/join/predicates.rb",
              "lib/locomotive/relational_algebra/operators/join/theta_join.rb",
              "lib/locomotive/relational_algebra/operators/projections.rb",
              "lib/locomotive/relational_algebra/operators/projections/attach.rb",
              "lib/locomotive/relational_algebra/operators/projections/projection.rb",
              "lib/locomotive/relational_algebra/operators/ranking.rb",
              "lib/locomotive/relational_algebra/operators/ranking/basic_ranking.rb",
              "lib/locomotive/relational_algebra/operators/ranking/rank.rb",
              "lib/locomotive/relational_algebra/operators/ranking/rank_lists.rb",
              "lib/locomotive/relational_algebra/operators/ranking/row_id.rb",
              "lib/locomotive/relational_algebra/operators/ranking/row_number.rb",
              "lib/locomotive/relational_algebra/operators/ranking/row_rank.rb",
              "lib/locomotive/relational_algebra/operators/serialization.rb",
              "lib/locomotive/relational_algebra/operators/serialization/basic_serialize.rb",
              "lib/locomotive/relational_algebra/operators/serialization/serialize_relation.rb",
              "lib/locomotive/relational_algebra/operators/set.rb",
              "lib/locomotive/relational_algebra/operators/set/basic_set.rb",
              "lib/locomotive/relational_algebra/operators/set/difference.rb",
              "lib/locomotive/relational_algebra/operators/set/union.rb",
              "lib/locomotive/relational_algebra/operators/set/distinct.rb",
              "lib/locomotive/relational_algebra/operators/tables.rb",
              "lib/locomotive/relational_algebra/operators/tables/literal_table.rb",
              "lib/locomotive/relational_algebra/operators/tables/nil.rb",
              "lib/locomotive/relational_algebra/operators/tables/ref_table.rb",
              "lib/locomotive/relational_algebra/operators/typeing.rb",
              "lib/locomotive/relational_algebra/operators/typeing/cast.rb",
              "lib/locomotive/relational_algebra/operators/error.rb",
              "lib/locomotive/relational_algebra/operators/error/error.rb",
              "lib/locomotive/relational_algebra/ordering.rb",
              "lib/locomotive/relational_algebra/query_information.rb",
              "lib/locomotive/relational_algebra/rel_alg_ast_node.rb",
              "lib/locomotive/relational_algebra/rel_alg_exceptions.rb",
              "lib/locomotive/relational_algebra/schema.rb",
              "lib/locomotive/relational_algebra/types.rb",
              "lib/locomotive/tree_helpers.rb",
              "lib/locomotive/tree_helpers/annotations.rb",
              "lib/locomotive/tree_helpers/ast.rb",
              "lib/locomotive/tree_helpers/ast_traversal.rb",
              "lib/locomotive/utils.rb",
              "lib/locomotive/utils/relalg2xml.rb",
              "lib/locomotive/utils/xml.rb"
            ]
  s.require_paths = ["lib"]
  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = false

  if s.respond_to? :secification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.secification_version = 3
  
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
#      s.add_runtime_dependency(%<activesupport>, [">= 3.0.0.beta"])
    else
#      s.add_dependency(%<activesupport>)
    end
  else
#    s.add_dependency(%<activesupport>)
  end
end
