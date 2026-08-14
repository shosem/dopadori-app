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

ActiveRecord::Schema[8.1].define(version: 2026_08_13_125920) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alternative_actions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "time_span", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_alternative_actions_on_user_id"
  end

  create_table "urges", force: :cascade do |t|
    t.bigint "alternative_action_id"
    t.datetime "created_at", null: false
    t.boolean "gave_in", default: false, null: false
    t.text "memo"
    t.integer "resolved", default: 0, null: false
    t.integer "trigger"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["alternative_action_id"], name: "index_urges_on_alternative_action_id"
    t.index ["user_id"], name: "index_urges_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "alternative_actions", "users"
  add_foreign_key "urges", "alternative_actions", on_delete: :nullify
  add_foreign_key "urges", "users"
end
