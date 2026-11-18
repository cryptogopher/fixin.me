module CoreExt::Arel::TreeManager::StatementMethods
  def with=(expr)
    @ast.with = expr
    self
  end
end
