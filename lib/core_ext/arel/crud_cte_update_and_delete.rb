module CoreExt::Arel::CrudCteUpdateAndDelete
  def compile_update(...)
    um = super
    um.with = subqueries
    um
  end

  def compile_delete(...)
    dm = super
    dm.with = subqueries
    dm
  end
end
