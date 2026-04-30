# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the
#   bin/rails db:seed
# command (or created alongside the database with db:setup).
# Seeding process should be idempotent.

User.transaction do
  break if User.find_by status: :admin

  email = Rails.configuration.admin
  password_length = SecureRandom.rand(Rails.configuration.devise.password_length)
  password = SecureRandom.alphanumeric(password_length)

  User.create!(email: email, password: password, status: :admin) do |user|
    user.skip_confirmation!
    print "Creating #{user.status} account '#{user.email}'" \
      " with password '#{user.password}'..."
  end
  puts "done."
rescue ActiveRecord::RecordInvalid => exception
  puts "failed.", exception.message
end

# Formulas will be deleted as dependent on Quantities
#[Source, Quantity, Unit].each { |model| model.defaults.delete_all }

load "db/seeds/units.rb"
