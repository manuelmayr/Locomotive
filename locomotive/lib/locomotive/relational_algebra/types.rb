module Locomotive

module RelationalAlgebra

class RType
  include Singleton
  include Locomotive::XML

  class << self
    alias :type :instance
  end

  def initialize()
    if self.class == RType
      raise AbstractClassError,
            "#{self.class} is an abstract class" 
    end
  end

  def clone
    # since all types are singletons
    # we can return the object itself
    self
  end

  def to_xml
    self.class.to_s.split("::").last.downcase[1..-1]
  end

  def inspect
    "<#{self.class.to_s.split('::').last}>"
  end
end
class RDbl < RType; end
class RDec < RDbl; end
class RInt < RDec; end
class RNat < RInt; end

class RStr < RType; end

class RBool < RType; end

#
# An atomic value constists of a value an
# its associated type
#
class RAtomic
  extend Locomotive::TypeChecking::Signature
  include Locomotive::XML

  def_node :_value_

  attr_accessor :value,
                :type
  def_sig :type=, RType

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
    RAtomic.new(self.value,
               self.type)
  end
end


[:r_dbl, :r_dec, :r_int, :r_nat, :r_str, :r_bool].each do |meth|
  meth_ = meth.classify.to_sym
  define_method(meth_) do |val|
    RAtomic.new(val, 
                ::Locomotive::RelationalAlgebra.
                const_get(meth_).type)
  end
end

end

end
