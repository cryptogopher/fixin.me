class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users do |t|
      ## Commented fields left for reference/inclusion in future migrations.

      ## Database authenticatable
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string :reset_password_token, index: {unique: true}
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Confirmable
      t.string :confirmation_token, index: {unique: true}
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      # Only if using reconfirmable.
      t.string :unconfirmed_email, limit: 2**6

      ## Trackable
      # t.integer :sign_in_count, default: 0, null: false
      # t.datetime :current_sign_in_at
      # t.datetime :last_sign_in_at
      # t.string :current_sign_in_ip
      # t.string :last_sign_in_ip

      ## Lockable
      # Only if unlock strategy is :email or :both.
      # t.string :unlock_token, index: {unique: true}
      # t.datetime :locked_at
      # Only if lock strategy is :failed_attempts.
      # t.integer :failed_attempts, default: 0, null: false 
    end
  end
end
