class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.references :user, foreign_key: {on_delete: :cascade}
      t.string :symbol, null: false, limit: 15
      t.text :description
      t.float :multiplier, null: false, limit: Float::MANT_DIG, default: 1.0
      t.references :base, foreign_key: {to_table: :units, on_delete: :cascade}

      t.timestamps
    end
    add_index :units, [:user_id, :symbol]
    add_index :units, [:id, :user_id]
  end
end
