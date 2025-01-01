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

ActiveRecord::Schema[7.2].define(version: 2025_01_01_112522) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "journals", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.integer "emotion", default: 0, null: false
    t.string "artist_name", null: false
    t.string "song_name", null: false
    t.string "preview_url"
    t.string "album_image"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spotify_track_id"
    t.index ["user_id"], name: "index_journals_on_user_id"
  end

  create_table "spotify_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["refresh_token"], name: "index_spotify_tokens_on_refresh_token", unique: true
    t.index ["user_id"], name: "index_spotify_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "journals", "users"
  add_foreign_key "spotify_tokens", "users"
end
