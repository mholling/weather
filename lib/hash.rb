class Hash
  def deep_merge(other)
    hash = dup
    other.keys.each do |key|
      if other[key].is_a?(Hash) && self[key].is_a?(Hash)
        hash[key] = hash[key].deep_merge(other[key])
      else
        hash[key] = other[key]
      end
    end
    hash
  end
  
  def deep_merge!(hash)
    self.replace deep_merge(hash)
  end
end

