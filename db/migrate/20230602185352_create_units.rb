class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.references :user, foreign_key: {on_delete: :cascade}
      t.string :symbol, null: false, limit: 2**4
      t.text :description, limit: 2**16
      t.float :multiplier, null: false, limit: Float::MANT_DIG, default: 1.0
      t.references :base, foreign_key: {to_table: :units, on_delete: :cascade}
      t.timestamps

      # Constraints:
      # * symbol has to be unique
      t.index [:user_id, :symbol], unique: true
      # * unit has to belong to the same user as quantity (used by :readouts)
      t.index [:id, :user_id], unique: true
    end
  end
end
