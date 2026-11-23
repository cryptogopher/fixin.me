class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}
      t.string :label, null: false, limit: 2**5
      t.text :description, limit: 2**16
      t.references :supertag, foreign_key: {to_table: :tags, on_delete: :cascade}
      t.timestamps
      # Cached, computed from other attributes.  NULL default to ensure value
      # has been properly initialized.
      t.integer :depth, null: false

      # Constraints:
      #  * label has to be unique
      t.index [:user_id, :label], unique: true
      #  * supertag cannot reference self
      t.check_constraint 'id != supertag_id', name: :self_reference
      #  * supertag has to belong to the same user as tag
      t.index [:id, :user_id], unique: true
      t.foreign_key :tags, primary_key: [:id, :user_id],
        column: [:supertag_id, :user_id], name: :user_mismatch
    end
  end
end
