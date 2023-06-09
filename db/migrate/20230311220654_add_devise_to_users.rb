class AddDeviseToUsers < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      ## NOTE: commented fields left for reference/inclusion in future migrations

      ## Database authenticatable
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Confirmable
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      # Only if using reconfirmable
      t.string :unconfirmed_email, limit: 64

      ## Trackable
      # t.integer :sign_in_count, default: 0, null: false
      # t.datetime :current_sign_in_at
      # t.datetime :last_sign_in_at
      # t.string :current_sign_in_ip
      # t.string :last_sign_in_ip

      ## Lockable
      # t.string :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at
      # Only if lock strategy is :failed_attempts
      # t.integer :failed_attempts, default: 0, null: false 
    end

    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token, unique: true
    # add_index :users, :unlock_token, unique: true
  end
end
