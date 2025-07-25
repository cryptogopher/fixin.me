# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_01_21_230456) do
  create_table "quantities", charset: "utf8mb4", collation: "utf8mb4_0900_as_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name", limit: 31, null: false
    t.text "description"
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "depth", default: 0, null: false
    t.string "pathname", limit: 511, null: false
    t.index ["parent_id"], name: "index_quantities_on_parent_id"
    t.index ["user_id", "parent_id", "name"], name: "index_quantities_on_user_id_and_parent_id_and_name", unique: true
    t.index ["user_id"], name: "index_quantities_on_user_id"
  end

  create_table "readouts", charset: "utf8mb4", collation: "utf8mb4_0900_as_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "quantity_id", null: false
    t.bigint "unit_id"
    t.decimal "value", precision: 30, scale: 15, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quantity_id", "created_at"], name: "index_readouts_on_quantity_id_and_created_at", unique: true
    t.index ["quantity_id"], name: "index_readouts_on_quantity_id"
    t.index ["unit_id"], name: "index_readouts_on_unit_id"
    t.index ["user_id"], name: "index_readouts_on_user_id"
  end

  create_table "units", charset: "utf8mb4", collation: "utf8mb4_0900_as_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.string "symbol", limit: 15, null: false
    t.text "description"
    t.decimal "multiplier", precision: 30, scale: 15, default: "1.0", null: false
    t.bigint "base_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_id"], name: "index_units_on_base_id"
    t.index ["user_id", "symbol"], name: "index_units_on_user_id_and_symbol", unique: true
    t.index ["user_id"], name: "index_units_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_as_ci", force: :cascade do |t|
    t.string "email", limit: 64, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email", limit: 64
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "quantities", "quantities", column: "parent_id"
  add_foreign_key "quantities", "users"
  add_foreign_key "readouts", "quantities"
  add_foreign_key "readouts", "units"
  add_foreign_key "readouts", "users"
  add_foreign_key "units", "units", column: "base_id"
  add_foreign_key "units", "users"
end
