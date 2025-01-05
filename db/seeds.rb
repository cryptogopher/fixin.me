# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the
#   bin/rails db:seed
# command (or created alongside the database with db:setup).
# Seeding process should be idempotent.

User.transaction do
  break if User.find_by status: :admin

  User.create! email: Rails.configuration.admin, password: 'admin', status: :admin do |user|
    user.skip_confirmation!
    print "Creating #{user.status} account '#{user.email}' with password '#{user.password}'..."
  end
  puts "done."

rescue ActiveRecord::RecordInvalid => exception
  puts "failed. #{exception.message}"
end

# Formulas will be deleted as dependent on Quantities
#[Source, Quantity, Unit].each { |model| model.defaults.delete_all }

# To clear contents of the table, use #truncate instead of #delete_all. This
# avoids foreign_key constraints errors.
require_relative 'seeds/units.rb'
