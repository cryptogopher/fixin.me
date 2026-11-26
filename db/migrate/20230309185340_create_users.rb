class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, limit: 2**6, index: {unique: true}
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
