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

ActiveRecord::Schema[8.1].define(version: 2026_08_27_105507) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "expense_item_participants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "expense_item_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expense_item_id", "user_id"], name: "idx_item_participants", unique: true
    t.index ["expense_item_id"], name: "index_expense_item_participants_on_expense_item_id"
    t.index ["user_id"], name: "index_expense_item_participants_on_user_id"
  end

  create_table "expense_items", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.bigint "expense_id", null: false
    t.string "name", null: false
    t.string "split_type", default: "equal"
    t.datetime "updated_at", null: false
    t.index ["expense_id"], name: "index_expense_items_on_expense_id"
  end

  create_table "expense_splits", force: :cascade do |t|
    t.decimal "amount_owed", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.bigint "expense_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expense_id", "user_id"], name: "index_expense_splits_on_expense_id_and_user_id", unique: true
    t.index ["expense_id"], name: "index_expense_splits_on_expense_id"
    t.index ["user_id"], name: "index_expense_splits_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.date "date", default: -> { "CURRENT_DATE" }
    t.string "description", null: false
    t.bigint "paid_by_id", null: false
    t.decimal "tax", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["paid_by_id"], name: "index_expenses_on_paid_by_id"
  end

  create_table "settlements", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "date", default: -> { "CURRENT_DATE" }
    t.text "notes"
    t.bigint "payee_id", null: false
    t.bigint "payer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["payee_id"], name: "index_settlements_on_payee_id"
    t.index ["payer_id"], name: "index_settlements_on_payer_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "mobile_number"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "expense_item_participants", "expense_items", on_delete: :cascade
  add_foreign_key "expense_item_participants", "users", on_delete: :cascade
  add_foreign_key "expense_items", "expenses", on_delete: :cascade
  add_foreign_key "expense_splits", "expenses", on_delete: :cascade
  add_foreign_key "expense_splits", "users", on_delete: :cascade
  add_foreign_key "expenses", "users", column: "paid_by_id"
  add_foreign_key "settlements", "users", column: "payee_id"
  add_foreign_key "settlements", "users", column: "payer_id"
end
