class CreateQuantities < ActiveRecord::Migration[8.1]
  def change
    create_table :quantities do |t|
      t.references :user, foreign_key: {on_delete: :cascade}
      t.string :name, null: false, limit: 2**5
      t.text :description, limit: 2**16
      t.references :parent, foreign_key: {to_table: :quantities, on_delete: :cascade}
      t.timestamps
      # Cached, computed from other attributes.  NULL default to ensure value
      # has been properly initialized.
      t.integer :depth, null: false
      t.string :pathname, null: false, limit: 511

      # Constraints:
      # * name has to be unique
      t.index [:user_id, :parent_id, :name], unique: true
      # * quantity has to belong to the same user as unit (used by :readouts)
      t.index [:id, :user_id], unique: true
    end
  end
end
