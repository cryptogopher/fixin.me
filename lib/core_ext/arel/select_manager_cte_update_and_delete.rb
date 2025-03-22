module CoreExt::Arel::SelectManagerCteUpdateAndDelete
  def subqueries
    @ast.with
  end
end
