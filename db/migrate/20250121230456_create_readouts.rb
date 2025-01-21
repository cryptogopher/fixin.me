class CreateReadouts < ActiveRecord::Migration[7.2]
  def change
    create_table :readouts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :quantity, null: false, foreign_key: true
      t.references :unit, foreign_key: true
      t.decimal :value, null: false, precision: 30, scale: 15
      #t.references :collector, foreign_key: true
      #t.references :device, foreign_key: true

      t.timestamps null: false
    end
    add_index :readouts, [:quantity_id, :created_at], unique: true
  end
end
