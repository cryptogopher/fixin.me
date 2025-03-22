module CoreExt::Arel::Visitors::ToSqlCteUpdateAndDelete
  def visit_Arel_Nodes_DeleteStatement(o, collector)
    if o.with
      collector = visit o.with, collector
      collector << " "
    end

    super
  end

  def visit_Arel_Nodes_UpdateStatement(o, collector)
    if o.with
      collector = visit o.with, collector
      collector << " "
    end

    super
  end
end
