module Locomotive

module Engines 

module Sql

class Engine
  def initialize(ar = nil)
    @ar = ar
  end

  def connection
    @ar.connection
  end

  def adapter_name
    @adapter_name ||= connection.adapter_name
  end

  def method_missing(method, *args, &block)
    @ar.connection.send(method, *args, &block)
  end

end

end

end

end
