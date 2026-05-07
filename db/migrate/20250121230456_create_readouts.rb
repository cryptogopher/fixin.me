class CreateReadouts < ActiveRecord::Migration[8.1]
  def change
    create_table :notes do |t|
      t.text :text, null: false

      t.timestamps
    end

    create_table :measurements do |t|
      t.datetime :taken_at, null: false
      #t.references :collector, foreign_key: true
      #t.references :device, foreign_key: true
      t.references :note, foreign_key: {on_delete: :nullify}

      t.timestamps
    end
    add_index :measurements, :taken_at

    # Defining Readouts as a super-/subclass polymorphic relations for different
    # subclass data types (numeric, string, file) is not possible with proper
    # referential integrity constraints. The required constraints are:
    # * for every subclass record to have superclass record,
    # * for every superclass record to have only one type of subclass record,
    # * for every superclass record to have subclass record (unenforcable).
    #   * this can be partially remedied by making superlass an abstract class in
    #     Rails and disallow direct creation of records, but direct data
    #     manipulation can still break referential integrity.
    # Defining separate {Numeric,Text,File}_Readouts tables would make the
    # unique index constraint unenforcable.
    create_table :readouts do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}
      t.references :measurement, foreign_key: {on_delete: :cascade}
      t.references :quantity, null: false, foreign_key: {on_delete: :cascade}
      t.integer :category, null: false, default: 0
      t.float :value, null: false, limit: Float::MANT_DIG
      t.references :unit, null: false, foreign_key: {on_delete: :cascade}
      # TODO: consider additional columns to allow wider range of value types
      # t.text :text
      # t.datetime :time
      # t.references :file
      # Possibly mutually exclusive with :unit or check constraint for:
      #   :unit is not null <=> :value is not null

      t.timestamps
    end
    add_index :readouts, [:measurement_id, :quantity_id, :category]
    add_foreign_key :readouts, :quantities, column: [:quantity_id, :user_id],
      primary_key: [:id, :user_id]
    add_foreign_key :readouts, :units, column: [:unit_id, :user_id],
      primary_key: [:id, :user_id]

    # TODO: remove below tables after current setup verified
    #create_table :numeric_values do |t|
    #  t.references :readout, null: false, foreign_key: {on_delete: :cascade}
    #  t.float :value, null: false, limit: Float::MANT_DIG
    #  t.references :unit, null: false, foreign_key: {on_delete: :cascade}
    #  # + generated, not stored column :value_type
    #  # + foreign key constraint to readouts: [:readout_id, :value_id, :value_type]
    #  # or 2 constraints: [:readout_id, :value_id], [:value_id, :value_type]
    #  # if readouts.value_id needed, otherwise just one constraint:
    #  # [:readout_id, :value_type]
    #end

    #create_table :string_values do |t|
    #  t.references :readout, null: false, foreign_key: {on_delete: :cascade}
    #  t.string :value, null: false, limit: 32
    #end
  end
end
