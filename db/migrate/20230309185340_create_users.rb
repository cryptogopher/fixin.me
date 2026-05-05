class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, limit: 64
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :users, :email
  end
end
