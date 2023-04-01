# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the
#   bin/rails db:seed
# command (or created alongside the database with db:setup).
# Seeding process should be idempotent.

User.transaction do
  User.find_or_create_by!(status: :admin) do |user|
    user.email = Rails.configuration.admin
    user.password = 'admin'
    puts "Admin account '#{user.email}' created with default password '#{user.password}'"
  end
end
