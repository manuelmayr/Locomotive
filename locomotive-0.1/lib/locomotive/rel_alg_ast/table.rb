module Locomotive

module RelAlgAst

class Table < RelAlgAstNode
private

public

  cattr_accessor :engine
  attr_reader :engine

  def initialize(name, engine = nil)
    super(:ref_tbl, name)
    @engine = engine || Table.engine
  end

  def columns
    @columns ||= engine.columns(value, "#{value} columns")
  end
  
  def reset
    @columns = nil
  end

end

end

end
