class CreateUnits < ActiveRecord::Migration[7.0]
  def change
    create_table :units do |t|
      t.references :user, foreign_key: true
      t.string :symbol, null: false
      t.string :name
      t.decimal :multiplier, null: false, precision: 30, scale: 15, default: 1.0
      t.references :base

      t.timestamps null: false
    end
    add_index :units, [:user_id, :symbol], unique: true
  end
end
