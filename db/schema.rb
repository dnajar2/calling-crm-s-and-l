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

ActiveRecord::Schema[8.1].define(version: 2025_12_30_195746) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "calendars", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "public_token"
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["public_token"], name: "index_calendars_on_public_token", unique: true
    t.index ["user_id"], name: "index_calendars_on_user_id"
  end

  create_table "clients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "event_notes", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.boolean "follow_up_required", default: false, null: false
    t.datetime "occurred_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "visible_to_client", default: false, null: false
    t.index ["event_id", "created_at"], name: "index_event_notes_on_event_id_and_created_at"
    t.index ["event_id"], name: "index_event_notes_on_event_id"
    t.index ["follow_up_required"], name: "index_event_notes_on_follow_up_required", where: "(follow_up_required = true)"
    t.index ["user_id"], name: "index_event_notes_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "calendar_id", null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_time"
    t.datetime "start_time"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["calendar_id"], name: "index_events_on_calendar_id"
    t.index ["client_id"], name: "index_events_on_client_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.vector "embedding", limit: 768
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["embedding"], name: "index_notes_on_embedding", using: :ivfflat
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "email_verified", default: false
    t.string "name"
    t.string "password_digest"
    t.string "provider"
    t.string "refresh_token"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "calendars", "users"
  add_foreign_key "clients", "users"
  add_foreign_key "event_notes", "events"
  add_foreign_key "event_notes", "users"
  add_foreign_key "events", "calendars"
  add_foreign_key "events", "clients"
  add_foreign_key "notes", "users"
end
