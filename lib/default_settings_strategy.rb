class DefaultSettingsStrategy < ActiveRecord::Migration::DefaultStrategy
  # Without `:if_not_exists`/`:if_exists` options it's impossible to change
  # migration status once migration fails partially. If `up` migration creates
  # some, but not all objects, its status is not updated from `down` to `up`.
  # Then it's impossible to migrate: a) up - due to `already exists` errors and
  # b) down - due to migration status.
  # Using `force: :cascade` does nothing on MySQL, so `force:` is useless.
  # Adding `null: false` here somehow does not show up in schema files, be careful!
  # TODO: add_foreign_key {on_delete: :cascade} ?
  DEFAULTS = {
    add_check_constraint: {if_not_exists: true},
    add_column:           {if_not_exists: true},
    add_foreign_key:      {if_not_exists: true},
    add_index:            {if_not_exists: true, unique: true},
    # Timestamps are by default `null: false, precision: true`.
    add_timestamps:       {if_not_exists: true},
    create_table:         {if_not_exists: true},
    drop_table:               {if_exists: true},
    remove_check_constraint:  {if_exists: true},
    remove_column:            {if_exists: true},
    remove_foreign_key:       {if_exists: true},
    remove_index:             {if_exists: true},
    remove_timestamps:        {if_exists: true},
  }
  DEFAULTS.default = {}
  DEFAULTS.freeze

  def method_missing(method, *args, **kwargs, &)
    conflicts = kwargs.has_key?(:force) ? [:if_not_exists, :if_exists] : []
    super(method, *args, **DEFAULTS[method.to_sym].except(*conflicts).merge(kwargs), &)
  end
end
