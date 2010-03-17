module Locomotive

module TypeChecking

class ArgumentError < StandardError; end

#
# Type checking method parameters
# 
module TypeChecker

  private
  
  def nth n
    n_ = n + 1
    th = case n_
           when 1 then 'st'
           when 2 then 'nd'
           else        'th'
         end
    "#{n_}#{th}"
  end

  public

  # check a simple argument type
  def check_arg_type(expected, obj, mtd, n=0)
    unless obj.kind_of? expected
      raise ArgumentError,
            "#{obj.class} assigned to #{expected} " \
            "for the #{nth n} argument of #{mtd}."
    end
  end

  # check an array type
  def check_arg_array_type(elem_type, arg, mtd, n=0)
    check_arg_type Array, arg, mtd, n
    arg.each_with_index do |x,i|
      unless x.kind_of? elem_type
        raise ArgumentError,
              "#{x.class} assigned to #{elem_type} for " \
              "the #{nth n} element of the #{nth n} "    \
              "argument of #{mtd}."
      end
    end
  end

  # check a hash type
  def check_arg_hash_type(key_type, elem_type, arg, mtd, n=0)
    check_arg_type Hash, arg, mtd, n
    arg.each_with_index do |item,i|
      check_arg_type key_type, item.first, mtd, n
      check_arg_type elem_type, item.last, mtd, n if elem_type.kind_of? Class
      check_arg_array_type elem_type.first, item.last, mtd, n if elem_type.kind_of? Array
    end
  end

  # check a variable argument type
  def check_vararg_type(expected, args, mtd, n=0)
    (n..args.length).each do |i|
      check_arg_type expected, args[i], mtd, i
    end
  end

  # make 'class'-methods out of the
  # methods defined above
  extend self
end

#
# Add declarative signature support
#
module Signature

  private

  def intercept_method(sym, types)
    # get the unbound method object
    mtd = instance_method(sym)
    helper = "_#{sym}_param_types_checked_helper".to_sym

    define_method(helper) do |*params|
      star_type, star_ind = nil, nil
      types.each_with_index do |t,i|
        t = star_type unless star_type.nil?
        arg = params[i]
        if t.kind_of? Class
          TypeChecker.check_arg_type t, arg, sym, i
        elsif t.empty?
          TypeChecker.check_arg_type Array, arg, sym, i
        elsif t.kind_of? Array
          TypeChecker.check_arg_array_type t[0], arg, sym, i
        elsif t.kind_of? Hash
          TypeChecker.check_arg_hash_type t.first.first,
                                          t.first.last,
                                          arg, sym, i
        else
          star_type, star_ind = t[0], i
          break
        end
      end
      TypeChecker.check_vararg_type star_type, params, sym, star_ind unless star_ind.nil?
      mtd.bind(self)
    end
    module_eval do
      define_method(sym) do |*params, &block|
        method(helper).call(*params).call(*params, &block)
      end
    end
  end

  public

  def def_sig sym, *types
    types.each_with_index do |t,i|
      unless t.kind_of? Class
        TypeChecker.check_arg_type Class, t, :def_sig, i unless t.kind_of? Array or t.kind_of? Hash
        TypeChecker.check_arg_type Class, t, :def_sig, i unless t.length <= 1
        TypeChecker.check_arg_array_type Class, t, :def_sig, i if t.kind_of? Array
      end
    end
    intercept_method(sym, types)
  end
end

end

end
