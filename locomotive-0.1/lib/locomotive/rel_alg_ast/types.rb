module Locomotive

module RelationalAlgebra

module Types

class Type
  include Singleton
  include Locomotive::XML

  def initialize()
    if self.class == Type
      raise AbstractClassError,
            "#{self.class} is an abstract class" 
    end
  end

  def clone
    # since all types are singletons
    # we can return the object itself
    self
  end

  def inspect
    "<#{self.class.to_s.split('::').last}>"
  end
end
class Dbl < Type; end
class Dec < Dbl; end
class Int < Dec; end
class Nat < Int; end

class Str < Type; end

class Bool < Type; end

#
# An atomic value constists of a value an
# its associated type
#
class Atomic
  extend Locomotive::TypeChecking::Signature
  include Locomotive::XML

  def_node :_value_

  attr_accessor :value,
                :type
  def_sig :type=, Type

  def initialize(val, ty)
    self.value,
    self.type = val, ty
  end

  def to_xml
    _value_ :type => type.to_xml do
      value
    end
  end

  def clone
    Atomic.new(self.value,
               self.type)
  end
end

end

end

end
