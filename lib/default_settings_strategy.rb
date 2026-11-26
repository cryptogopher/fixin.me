class DefaultSettingsStrategy < ActiveRecord::Migration::DefaultStrategy
  # Strategy methods can be invoked differently depending on whether changes are
  # applied from migration files in up or down direction (e.g. `change_table`
  # can be run as series of `remove_column` during #down) or from schema file.
  # Strategy has to be verified at least using:
  #   db:migrate + db:migrate VERSION=0
  #   db:reset + (multiple) db:schema:load (if schema file is used)

  # TODO: remove after commit
  #def create_table(table_name, **options, &)
  #  result = super(table_name, **apply_defaults(:create_table, options), &)
  #  add_constraints(table_name, columns(table_name)) unless migration.reverting?
  #  result
  #end

  #def change_table(table_name, **options)
  #  return super if migration.reverting?
  #  before, result, after = columns(table_name), super, columns(table_name)
  #  add_constraints(table_name, after - before)
  #  remove_constraints(table_name, (before - after).map(&:name))
  #  result
  #end

  #def drop_table(*table_names, **options)
  #  super(*table_names, **apply_defaults(:drop_table, options))
  #end

  #def remove_column(table_name, column_name, type = nil, **options)
  #  remove_constraints(table_name, [column_name])
  #  super
  #end

  def method_missing(method, *args, **kwargs, &)
    return super if migration.reverting?

    # SchemaDumper#table has hardcoded: `tbl.puts ", force: :cascade do |t|"`.
    # It collides with `if_not_exists`. Drop #except(*conflicts) after
    # https://github.com/rails/rails/issues/37392 is fixed.
    defaults = MIGRATION_DEFAULTS[method.to_sym]
    conflicts = defaults.has_key?(:if_not_exists) ? [:force] : []

    result = nil
    process_method(method, *args, **kwargs) do
      result = super(method, *args, **defaults.merge(kwargs.except(*conflicts)), &)
    end
    return result
  end

  def process_method(method, *args, **kwargs)
    case method.to_sym
    when :create_table
      yield
      add_constraints(args.first, columns(args.first))
    when :change_table
      before, _, after = columns(args.first), yield, columns(args.first)
      add_constraints(args.first, after - before)
      remove_constraints(args.first, (before - after).map(&:name))
    when :remove_column
      remove_constraints(args.first, [args.second])
      yield
    else
      yield
    end
  end

  private

  # `if_not_exists: true`/`if_exists: true` - are necessary fo every top level
  # migration statement. Without these options it's impossible to change
  # migration status once it fails in the middle. If migration is only applied
  # partially, its status is not updated. Then it's impossible to:
  #   a) migrate, because some objects have alredy been created/dropped and
  #   b) rollback, due to migration status.
  # `timestamps` - Rails defaults to `null: false, precision: true`, as expected.
  MIGRATION_DEFAULTS = {
    add_check_constraint:     {if_not_exists: true},
    create_table:             {if_not_exists: true},
    drop_table:               {if_exists: true},
    remove_check_constraint:  {if_exists: true},
  }
  MIGRATION_DEFAULTS.default = {}
  MIGRATION_DEFAULTS.freeze

  # SQLite does not enforce `limit` on string/text columns by default.  `text`
  # can be theoretically up to 1GB or longer, so roughly unlimited for practical
  # purposes. But the actual usable length depends on additional factors, like
  # compile time limits (`SQLITE_MAX_LENGTH` in SQLite) and probably other.
  # Limit is explicitly set to:
  #   a) be used by views/UI (Rails does not report limit for `text` column
  #   types, unless it is explicitly set) and
  #   b) be enforced by database constraint (below).
  # Length constraint is measured in codepoints (not bytes).
  def add_constraints(table_name, columns)
    # Do not run on db:schema:load, as constraints are dumped explicitly.
    return unless migration.name
    columns.select { |column| column.limit && [:string, :text].include?(column.type) }
      .each do |column|
        expression = "length(#{column.name}) <= #{column.limit}"
        name = "#{column.name}_length"
        add_check_constraint(table_name, expression, name: name)
      end
  end

  def remove_constraints(table_name, column_names)
    column_names.each do |column_name|
      remove_check_constraint(table_name, name: "#{column_name}_length")
    end
  end

  # TODO: remove after commit
  #def apply_defaults(method, options)
  #  defaults = MIGRATION_DEFAULTS[method]
  #  conflicts = defaults.has_key?(:if_not_exists) ? [:force] : []
  #  defaults.merge(options.except(*conflicts))
  #end
end
