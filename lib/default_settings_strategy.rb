class DefaultSettingsStrategy < ActiveRecord::Migration::DefaultStrategy
  COLUMN_DEFAULTS = {
    # TODO: all types `null: false` ?
    # TODO: references `foreign_key: {on_delete: :cascade}` ?
    # `timestamps` - Rails defaults to `null: false, precision: true`, which is
    #   expected.
    text: {limit: 2**16 - 1}
  }
  COLUMN_DEFAULTS.default = {}
  COLUMN_DEFAULTS.freeze

  module ColumnSettingsStrategy
    def column(name, type, **options)
      super(name, type, **COLUMN_DEFAULTS[type].merge(options))
      # SQLite does not enforce `limit` on string/text columns by default.
      # `text` can be theoretically up to 1GB or longer, so roughly unlimited
      # for practical purposes. But the actual usable length depends on
      # additional factors, like compile time limits (`SQLITE_MAX_LENGTH` in
      # SQLite) and probably other.
      # Limit is explicitly set to:
      #   a) be used by views/UI (Rails does not report limit for `text` column
      #   types, unless it is explicitly set) and
      #   b) be enforced by database constraint (below).
      # Length constraint is measured in codepoints (not bytes).
      if options[:limit] && [:string, :text].include?(type)
        check_constraint("length(#{name}) <= #{options[:limit]}", name: "#{name}_length")
      end
    end
  end
  ActiveRecord::ConnectionAdapters::TableDefinition.prepend ColumnSettingsStrategy

  # `if_not_exists: true`/`if_exists: true` - without these options it's impossible
  #   to change migration status once migration fails partially. If `up` migration
  #   creates some, but not all objects, its status is not updated from `down` to
  #   `up`. Then it's impossible to migrate: a) up - due to `already exists`
  #   errors and b) down - due to migration status. Similarily for `down`.
  MIGRATION_DEFAULTS = {
    add_check_constraint: {if_not_exists: true},
    add_column:           {if_not_exists: true},
    add_foreign_key:      {if_not_exists: true},
    add_index:            {if_not_exists: true, unique: true},
    add_timestamps:       {if_not_exists: true},
    create_join_table:  {force: :cascade},
    create_table:       {force: :cascade},
    drop_table:         {force: :cascade},
    remove_check_constraint:  {if_exists: true},
    remove_column:            {if_exists: true},
    remove_foreign_key:       {if_exists: true},
    remove_index:             {if_exists: true},
    remove_timestamps:        {if_exists: true},
  }
  MIGRATION_DEFAULTS.default = {}
  MIGRATION_DEFAULTS.freeze

  def method_missing(method, *args, **kwargs, &)
    conflicts = kwargs.has_key?(:force) ? [:if_not_exists, :if_exists] : []
    defaults = MIGRATION_DEFAULTS[method.to_sym].except(*conflicts)
    super(method, *args, **defaults.merge(kwargs), &)
  end
end
