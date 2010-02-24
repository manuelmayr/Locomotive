module Locomotive

module AstHelpers

# The purpose of this module is to enhance
# an instance with accessors on special labeled
# methods.
#
# Each instance of a class (with this module included)
# has methods 
#   *. o.ann_\w+
#   *. o.ann_\w+=
# to set and read the annotations.
module Annotations
  public

  # overwrite the respond_to method
  # to pretend there are ann_-methods
  def respond_to? sym
    if @annotations.member? sym
      true
    else
      super.responds_to? sym
    end
  end

  # set method_missing to overwrite
  # the behaviour of ann_-prefixed
  # methods
  def method_missing(key, *args)
    key_str = key.to_s

    # labeled ANN_PATTERN is not applicable in
    # this case due to ?<data>
    if /^ann_(?<data>\w+)=?/ =~ key_str
      @annotations ||= {}

      data_sym = data.to_sym
      if key_str[-1,1] == "=" then
        @annotations[data_sym] = args[0]
      else
        @annotations[data_sym]
      end

    else 
      super.method_missing(key, *args)
    end
  end

end

end

end
