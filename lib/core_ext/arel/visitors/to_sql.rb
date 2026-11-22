module CoreExt::Arel::Visitors::ToSql
  def visit_Arel_Nodes_DeleteStatement(o, collector)
    if o.with
      collector = visit o.with, collector
      collector << " "
    end

    super
  end
end
