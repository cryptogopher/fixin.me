class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email, null: false, limit: 64
      t.integer :status, null: false, default: 0

      t.timestamps null: false
    end
    add_index :users, :email, unique: true
  end
end
