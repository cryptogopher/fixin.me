module CoreExt::Arel::TreeManager::StatementMethodsCteUpdateAndDelete
  def with=(expr)
    @ast.with = expr
    self
  end
end
