class CreateQuantities < ActiveRecord::Migration[7.2]
  def change
    create_table :quantities do |t|
      t.references :user, foreign_key: true
      t.string :name, null: false, limit: 31
      t.text :description
      t.references :parent, foreign_key: {to_table: :quantities}

      t.timestamps null: false

      # Caches; can be computed from other attributes
      t.integer :depth, null: false, default: 0
      t.string :pathname, null: false, limit: 511
    end
    add_index :quantities, [:user_id, :parent_id, :name], unique: true
  end
end
