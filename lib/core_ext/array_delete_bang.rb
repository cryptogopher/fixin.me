module CoreExt
  module ArrayDeleteBang
    def delete!(obj)
      self.delete(obj)
      self
    end
  end
end

Array.prepend CoreExt::ArrayDeleteBang
