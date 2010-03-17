require "rake"

loco_lib = "lib/locomotive"

Gem::Specification.new do |sp|
  sp.name = "locomotive"
  sp.version = "0.01"
  sp.author = "Manuel Mayr"
  sp.email = "mayr@informatik.uni-tuebingen.de"
  sp.homepage = ""
  sp.platform = Gem::Platform::RUBY
  sp.summary = ""
  sp.files = [ "locomotive.rb",
               "#{loco_lib}/ast_helpers/annotations.rb",
               "#{loco_lib}/ast_helpers/ast.rb",
               "#{loco_lib}/ast_helpers/ast_traversal.rb",
               "#{loco_lib}/utils/ast2dot.rb", 
               "#{loco_lib}/utils/relalg2xml.rb", 
               "#{loco_lib}/ruby_ast/types.rb",
               "#{loco_lib}/ruby_ast/ast_exceptions.rb",
               "#{loco_lib}/rel_alg_ast/rel_alg_ast_node.rb",
               "#{loco_lib}/ruby_ast/ruby_ast_node.rb",
               "#{loco_lib}/ruby_ast/sexp_ast_helper.rb",
               "#{loco_lib}/ruby_ast/sexp_to_ast.rb",
               "#{loco_lib}/ruby_ast/boxed_type_inference_helper.rb",
               "#{loco_lib}/ruby_ast/boxed_type_inference.rb",
               "#{loco_lib}/translation/ruby_to_algebra.rb",
               "#{loco_lib}/rel_alg_ast/rel_alg_factory.rb",
               "#{loco_lib}/translation/ruby_to_algebra_helper.rb",
               "#{loco_lib}/translation/translation_exceptions.rb",
               "#{loco_lib}/rel_alg_ast/rel_alg_exceptions.rb",
               "#{loco_lib}/engine/sql/engine.rb",
               "#{loco_lib}/rel_alg_ast/table.rb",
               "#{loco_lib}/rel_alg_ast/rel_alg_ops.rb",
               "#{loco_lib}/rel_alg_ast/types.rb",
               "#{loco_lib}/misc/type_check.rb",
               "#{loco_lib}/rel_alg_ast/attributes.rb",
               "#{loco_lib}/misc/array_ext.rb",
               "#{loco_lib}/utils/xml.rb"
             ]
  sp.require_path = "."
  sp.test_files = FileList["{test}/**/*test.rb"].to_a
  sp.has_rdoc = false
# sp.extra_rdoc_files = ["README"]
# sp.add_dependency("dependency", ">= 0.x.x")
end


