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

ActiveRecord::Schema[7.2].define(version: 2025_12_11_045821) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "calendars", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "timezone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "public_token"
    t.index ["public_token"], name: "index_calendars_on_public_token", unique: true
    t.index ["user_id"], name: "index_calendars_on_user_id"
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "calendar_id", null: false
    t.bigint "client_id", null: false
    t.string "title"
    t.text "description"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["calendar_id"], name: "index_events_on_calendar_id"
    t.index ["client_id"], name: "index_events_on_client_id"
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding", limit: 768
    t.index ["embedding"], name: "index_notes_on_embedding", using: :ivfflat
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "calendars", "users"
  add_foreign_key "clients", "users"
  add_foreign_key "events", "calendars"
  add_foreign_key "events", "clients"
  add_foreign_key "notes", "users"
end
