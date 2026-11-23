module CoreExt::ActiveRecord::Relation
  ActiveRecord::Relation.class_eval do
    remove_const :INVALID_METHODS_FOR_UPDATE_AND_DELETE_ALL
    INVALID_METHODS_FOR_UPDATE_AND_DELETE_ALL = [:distinct]
  end
end
