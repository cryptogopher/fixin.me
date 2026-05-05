class CreateQuantities < ActiveRecord::Migration[8.1]
  def change
    create_table :quantities do |t|
      t.references :user, foreign_key: {on_delete: :cascade}
      t.string :name, null: false, limit: 31
      t.text :description
      t.references :parent, foreign_key: {to_table: :quantities, on_delete: :cascade}

      t.timestamps

      # Caches; can be computed from other attributes
      t.integer :depth, null: false, default: 0
      t.string :pathname, null: false, limit: 511
    end
    add_index :quantities, [:user_id, :parent_id, :name]
    add_index :quantities, [:id, :user_id]
  end
end
