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

ActiveRecord::Schema.define(version: 101) do

  create_table "course_registrants", force: :cascade do |t|
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "course_registration_id"
    t.string "course_registration_type"
    t.integer "learndash_course_id"
    t.integer "purchased_order_id"
    t.integer "price"
    t.boolean "tax_exempt", default: false
    t.string "qb_item_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "course_registrations", force: :cascade do |t|
    t.string "token"
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "user_id"
    t.string "user_type"
    t.integer "learndash_course_id"
    t.string "status"
    t.text "status_steps"
    t.text "wizard_steps"
    t.datetime "submitted_at"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["owner_id", "owner_type"], name: "index_course_registrations_on_owner_id_and_owner_type"
    t.index ["status"], name: "index_course_registrations_on_status"
    t.index ["token"], name: "index_course_registrations_on_token"
  end

  create_table "learndash_courses", force: :cascade do |t|
    t.integer "course_id"
    t.string "status"
    t.string "title"
    t.string "link"
    t.string "slug"
    t.integer "roles_mask"
    t.boolean "authenticate_user", default: false
    t.boolean "can_register", default: false
    t.integer "regular_price"
    t.integer "member_price"
    t.string "qb_item_name"
    t.boolean "tax_exempt", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "learndash_enrollments", force: :cascade do |t|
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "learndash_course_id"
    t.integer "learndash_user_id"
    t.datetime "last_synced_at"
    t.string "progress_status"
    t.integer "last_step"
    t.integer "steps_completed"
    t.integer "steps_total"
    t.datetime "date_started"
    t.datetime "date_completed"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "learndash_users", force: :cascade do |t|
    t.integer "owner_id"
    t.string "owner_type"
    t.datetime "last_synced_at"
    t.integer "user_id"
    t.string "email"
    t.string "username"
    t.string "password"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "email", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "roles_mask"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
