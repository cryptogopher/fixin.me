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

Unit.transaction do
  Unit.defaults.delete_all

  unit_1 = Unit.create symbol: "1",   name: "dimensionless, one"
           Unit.create symbol: "%",   base: unit_1, multiplier: 1e-2, name: "percent"
           Unit.create symbol: "‰",   base: unit_1, multiplier: 1e-3, name: "promille"
           Unit.create symbol: "‱",   base: unit_1, multiplier: 1e-4, name: "basis point"
           Unit.create symbol: "ppm", base: unit_1, multiplier: 1e-6, name: "parts per million"

  unit_g = Unit.create symbol: "g",  name: "gram"
           Unit.create symbol: "ug", base: unit_g, multiplier: 1e-6, name: "microgram"
           Unit.create symbol: "mg", base: unit_g, multiplier: 1e-3, name: "milligram"
           Unit.create symbol: "kg", base: unit_g, multiplier: 1e3,  name: "kilogram"

  Unit.create symbol: "kcal", name: "kilocalorie"
end
