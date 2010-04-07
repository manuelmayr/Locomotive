class Hash
  def flip
    self.collect do |k,v|
      [v,k]
    end.to_hash
  end
end
