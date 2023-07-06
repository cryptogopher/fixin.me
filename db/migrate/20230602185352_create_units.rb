class CreateUnits < ActiveRecord::Migration[7.0]
  def change
    create_table :units do |t|
      t.references :user, foreign_key: true
      t.string :symbol
      t.string :name
      t.decimal :multiplier, precision: 30, scale: 15

      t.references :base
      t.integer :lft, null: false
      t.integer :rgt, null: false

      t.timestamps
    end
    add_index :units, [:user_id, :symbol], unique: true
    add_index :units, :lft
    add_index :units, :rgt
  end
end
