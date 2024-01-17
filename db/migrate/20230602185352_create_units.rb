class CreateUnits < ActiveRecord::Migration[7.0]
  def change
    create_table :units do |t|
      t.references :user, foreign_key: true
      t.string :symbol
      t.string :name
      t.decimal :multiplier, precision: 30, scale: 15
      t.references :base

      t.timestamps
    end
    add_index :units, [:user_id, :symbol], unique: true
  end
end
