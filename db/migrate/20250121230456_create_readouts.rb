class CreateReadouts < ActiveRecord::Migration[7.2]
  def change
    create_table :readouts do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}
      t.references :quantity, null: false, foreign_key: true
      # :category + :value + :unit as a separate table? (NumericValue, TextValue)
      t.integer :category, null: false, default: 0
      t.float :value, null: false, limit: Float::MANT_DIG
      t.references :unit, foreign_key: true
      #t.references :collector, foreign_key: true
      #t.references :device, foreign_key: true

      t.timestamps null: false
    end
    add_index :readouts, [:quantity_id, :created_at], unique: true
  end
end
