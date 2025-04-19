class ApplicationRecord < ActiveRecord::Base
  class << self
    # Cached attribute has non-user assignable value calculated from other
    # attributes' values on create/update. This simplifies and speeds up
    # actions, especially for recursively calculated values. Because value can
    # be changed on update, it is not same as #attr_readonly.
    def attr_cached(*names)
      names.each { |name| alias_method :"#{name}=", :assign_cached_attribute }
    end
  end

  def assign_cached_attribute(value)
    raise ActiveRecord::ReadonlyAttributeError
  end

  primary_abstract_class
end
