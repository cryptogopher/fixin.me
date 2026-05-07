class DefaultSettingsStrategy < ActiveRecord::Migration::DefaultStrategy
  COLUMN_DEFAULTS = {
    # TODO: all types `null: false` ?
    # TODO: references `foreign_key: {on_delete: :cascade}` ?
    # `timestamps` - Rails defaults to `null: false, precision: true`.
    # `limit:` for `text` - `text` can be theoretically up to 1GB or
    #   longer, so roughly unlimited for practical purposes. But:
    #   * the actual usable length depends on additional factors, like compile
    #     time limits (`SQLITE_MAX_LENGTH` in SQLite), runtime settings
    #     (`max_allowed_packet` in MySQL) and probably other,
    #   * Rails does not report limit for `text` column types, unless it is
    #     explicitly set.
    #   The decision is to always set safe limit and enforce it by validations, to
    #   avoid surprises (e.g. text truncation) when saving to dabatase.
    text: {limit: 2**16 - 1}
  }
  COLUMN_DEFAULTS.default = {}
  COLUMN_DEFAULTS.freeze

  module ColumnSettingsStrategy
    def column(name, type, **options)
      super(name, type, **COLUMN_DEFAULTS[type].merge(options))
    end
  end
  ActiveRecord::ConnectionAdapters::TableDefinition.prepend ColumnSettingsStrategy

  # `force: :cascade` - does nothing on MySQL, so `force:` is useless.
  # `if_not_exists: true`/`if_exists: true` - without these options it's impossible
  #   to change migration status once migration fails partially. If `up` migration
  #   creates some, but not all objects, its status is not updated from `down` to
  #   `up`. Then it's impossible to migrate: a) up - due to `already exists`
  #   errors and b) down - due to migration status.
  MIGRATION_DEFAULTS = {
    add_check_constraint: {if_not_exists: true},
    add_column:           {if_not_exists: true},
    add_foreign_key:      {if_not_exists: true},
    add_index:            {if_not_exists: true, unique: true},
    add_timestamps:       {if_not_exists: true},
    create_table:         {if_not_exists: true},
    drop_table:               {if_exists: true},
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
