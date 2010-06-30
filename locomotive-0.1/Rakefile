# -*- encoding: utf-8 -*-
require "rake/gempackagetask"
require "rake/testtask"
require "rake/clean"

gemspec_file = "locomotive.gemspec"

spec = eval(File.read(gemspec_file))

task :default => [:package]

# customizing gem package
desc "Creating a gem package"
Rake::GemPackageTask.new(spec) do |pkg| end

desc "Run basic unit tests"
Rake::TestTask.new(:tests) do |t|
  t.pattern = 'tests/unit/locomotive/*_test.rb'
  t.verbose = true
end

desc "Removes trailing whitespace"
task :whitespace do
  sh %{find . -name '*.rb' -exec sed -i '' 's/ *$//g' {} \\;}
end

desc "Remove bothering vim swap files"
task :vim_clean do
  sh %{find . -name '.*.swp' -delete}
end

# clean the  repository
CLEAN.include("pkg", "rspec")
