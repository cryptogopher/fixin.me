module CoreExt::ActiveRecord::QueryMethods
  class SelectChain
    def initialize(scope)
      @scope = scope
    end

    def lag(expr, offset: 1, default: nil)
      case expr
      when Hash
      when Symbol
        expr = {expr => "lag_#{expr}"}
      else
        raise ArgumentError, "Unsupported expression argument type: #{expr.class.name}."
      end

      expr.each do |column, column_alias|
        @scope._select!(
          Arel::Nodes::NamedFunction.new(
            'LAG',
            [@scope.table[column], offset, Arel::Nodes.build_quoted(default)]
          ).over().as(column_alias)
        )
      end

      @scope
    end
  end

  def self.included(base)
    base.prepend SelectWithSelectChain
  end
end

module SelectWithSelectChain
  def select(*fields)
    return super if !fields.empty? || block_given?
    ActiveRecord::Relation::SelectChain.new(spawn)
  end
end
