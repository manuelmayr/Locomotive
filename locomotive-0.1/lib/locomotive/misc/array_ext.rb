class Array
  def flatten_once
    inject([]) { |v, e| v.concat(e)}
  end 
end
