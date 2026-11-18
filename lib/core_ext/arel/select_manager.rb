module CoreExt::Arel::SelectManager
  def subqueries
    @ast.with
  end
end
