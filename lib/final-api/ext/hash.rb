# Extension class for Hash
class Hash
  # Returns key case insensitively, if present
  def get_ikey(key_name)
    each do |key, value|
      return value if key.casecmp(key_name) == 0
    end
    
    nil
  end
end
