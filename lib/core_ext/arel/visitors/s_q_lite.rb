module CoreExt::Arel::Visitors::SQLite
  def visit_Arel_Nodes_UpdateStatement(o, collector)
    if o.with
      collector = visit o.with, collector
      collector << " "
    end

    super
  end
end
