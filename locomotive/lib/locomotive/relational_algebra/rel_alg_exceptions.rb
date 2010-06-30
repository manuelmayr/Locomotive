module Locomotive

module RelationalAlgebra

class IdError < StandardError; end
class AbstractClassError < StandardError; end
class Duplicates < StandardError; end
class CorruptedSchema < StandardError; end
class ITblsNotEqual < StandardError; end

class ArgumentException < StandardError; end

end

end
