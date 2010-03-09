module Locomotive

module RelAlgAst

class Table < RelAlgAstNode

  cattr_accessor :engine
  attr_reader :engine

  def initialize(name, engine = nil)
    super.initialize(:table, name)
    @engine = engine || Table.engine
  end

  def columns
    @columns ||= engine.columns(name, "#{name} columns")
  end
  
  def reset
    @columns = nil
  end

end

end

end
