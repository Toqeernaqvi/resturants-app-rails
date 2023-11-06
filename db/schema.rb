# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20220726093902) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "address_line", limit: 510, null: false
    t.string "short_code", limit: 510
    t.integer "status", default: 0
    t.integer "parent_status", default: 0
    t.string "addressable_type", limit: 510
    t.bigint "addressable_id"
    t.string "formatted_address", limit: 510
    t.string "suite_no", limit: 510
    t.string "street_number", limit: 510
    t.string "street", limit: 510
    t.string "city", limit: 510
    t.string "state", limit: 510
    t.string "zip", limit: 510
    t.float "latitude"
    t.float "longitude"
    t.time "starting_hours_of_operations"
    t.time "ending_hours_of_operations"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lunch_order_capacity", default: 0, null: false
    t.integer "dinner_order_capacity", default: 0, null: false
    t.text "notes"
    t.time "monday_first_start_time"
    t.time "tuesday_first_start_time"
    t.time "wednesday_first_start_time"
    t.time "thursday_first_start_time"
    t.time "friday_first_start_time"
    t.time "saturday_first_start_time"
    t.time "sunday_first_start_time"
    t.time "monday_first_end_time"
    t.time "tuesday_first_end_time"
    t.time "wednesday_first_end_time"
    t.time "thursday_first_end_time"
    t.time "friday_first_end_time"
    t.time "saturday_first_end_time"
    t.time "sunday_first_end_time"
    t.time "monday_second_start_time"
    t.time "tuesday_second_start_time"
    t.time "wednesday_second_start_time"
    t.time "thursday_second_start_time"
    t.time "friday_second_start_time"
    t.time "saturday_second_start_time"
    t.time "sunday_second_start_time"
    t.time "monday_second_end_time"
    t.time "tuesday_second_end_time"
    t.time "wednesday_second_end_time"
    t.time "thursday_second_end_time"
    t.time "friday_second_end_time"
    t.time "saturday_second_end_time"
    t.time "sunday_second_end_time"
    t.string "address_name", limit: 510
    t.integer "delayed_payout_days", default: 6
    t.decimal "discount_percentage", precision: 8, scale: 2, default: "0.0"
    t.decimal "rating_total", precision: 8, scale: 2, default: "0.0"
    t.integer "rating_count", default: 0
    t.decimal "average_rating", precision: 8, scale: 2, default: "0.0"
    t.decimal "buffet_price", precision: 8, scale: 2, default: "0.0"
    t.boolean "alert_email"
    t.boolean "add_contract_commission"
    t.integer "items_count", default: 0
    t.decimal "minimum_discount_price", precision: 8, scale: 4, default: "0.0"
    t.decimal "buffet_commission", precision: 8, scale: 4, default: "0.0"
    t.boolean "enable_marketplace", default: false
    t.string "time_zone"
    t.boolean "random_menu_images", default: false
    t.bigint "lunch_sequence_id"
    t.bigint "dinner_sequence_id"
    t.bigint "breakfast_sequence_id"
    t.bigint "buffet_sequence_id"
    t.bigint "user_id"
    t.text "delivery_instructions"
    t.boolean "enable_self_service", default: false
    t.integer "delivery_radius", default: 20
    t.decimal "delivery_cost", precision: 8, scale: 2, default: "0.0"
    t.integer "minimum_order_quantity", default: 1
    t.string "onfleet_team_id"
    t.integer "individual_meals_cutoff", default: 22
    t.integer "buffet_cutoff", default: 48
    t.string "logo", limit: 510
    t.string "stripe_acc_id"
    t.string "stripe_acc_link"
    t.string "stripe_acc_login"
    t.boolean "stripe_details_submitted", default: false
    t.integer "grouping_rows", default: 6
    t.integer "grouping_columns", default: 5
    t.index ["breakfast_sequence_id"], name: "index_addresses_on_breakfast_sequence_id"
    t.index ["buffet_sequence_id"], name: "index_addresses_on_buffet_sequence_id"
    t.index ["deleted_at"], name: "index_addresses_on_deleted_at"
    t.index ["dinner_sequence_id"], name: "index_addresses_on_dinner_sequence_id"
    t.index ["lunch_sequence_id"], name: "index_addresses_on_lunch_sequence_id"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "addresses_cuisineslists", force: :cascade do |t|
    t.bigint "address_id"
    t.bigint "cuisineslist_id"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id", "cuisineslist_id"], name: "index_addresses_cuisineslists_on_address_id_and_cuisineslist_id", unique: true
    t.index ["address_id"], name: "index_addresses_cuisineslists_on_address_id"
    t.index ["cuisineslist_id"], name: "index_addresses_cuisineslists_on_cuisineslist_id"
  end

  create_table "addresses_recurring_schedulers", force: :cascade do |t|
    t.bigint "address_id"
    t.bigint "recurring_scheduler_id"
    t.bigint "recurring_dynamic_section_id"
    t.index ["address_id"], name: "index_addresses_recurring_schedulers_on_address_id"
    t.index ["recurring_scheduler_id"], name: "index_addresses_recurring_schedulers_on_recurring_scheduler_id"
  end

  create_table "addresses_runningmenus", force: :cascade do |t|
    t.bigint "address_id"
    t.bigint "runningmenu_id"
    t.string "restaurant_task_id", limit: 510
    t.integer "acknowledge_receipt", default: 0
    t.integer "accept_orders", default: 0
    t.integer "accept_changes", default: 0
    t.integer "pre_week_email", default: 0
    t.string "summary_pdf", limit: 510
    t.string "summary_labels", limit: 510
    t.string "token", limit: 510
    t.integer "task_status", default: 0
    t.integer "rank"
    t.integer "pre_email", default: 0
    t.boolean "rejected_by_vendor", default: false
    t.text "reject_reason"
    t.string "before_pickup_job_id"
    t.integer "before_pickup_job_status", default: 0
    t.string "before_pickup_job_error"
    t.bigint "dynamic_section_id"
    t.index ["address_id"], name: "addresses_runningmenus_address_id_idx"
    t.index ["dynamic_section_id"], name: "index_addresses_runningmenus_on_dynamic_section_id"
    t.index ["runningmenu_id"], name: "addresses_runningmenus_runningmenu_id_idx"
  end

  create_table "addresses_vendors", force: :cascade do |t|
    t.integer "user_id"
    t.integer "address_id"
  end

  create_table "adjustments", force: :cascade do |t|
    t.bigint "restaurant_billing_id"
    t.date "adjustment_date"
    t.text "description"
    t.decimal "price", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "adjustable_type"
    t.bigint "adjustable_id"
    t.integer "adjustment_type", default: 0
    t.index ["adjustable_type", "adjustable_id"], name: "index_adjustments_on_adjustable_type_and_adjustable_id"
  end

  create_table "all_driver_shifts", force: :cascade do |t|
  end

  create_table "announcements", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "expiration"
    t.integer "status", default: 0
    t.boolean "admins", default: true
    t.boolean "users", default: true
    t.boolean "vendors", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "approvers", force: :cascade do |t|
    t.bigint "billing_id"
    t.string "name", limit: 510
    t.string "email", limit: 510
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "address_id"
    t.index ["billing_id"], name: "approvers_billing_id_idx"
  end

  create_table "ban_addresses", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "address_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "ban_addresses_address_id_idx"
    t.index ["company_id"], name: "ban_addresses_company_id_idx"
  end

  create_table "billings", force: :cascade do |t|
    t.bigint "company_id"
    t.integer "invoice_credit_card"
    t.string "customer_id", limit: 510
    t.string "stripe_cc_id", limit: 510
    t.string "name", limit: 510
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "address_id"
    t.integer "weekly_invoice", default: 0
    t.string "token", limit: 510
    t.decimal "delivery_fee", precision: 8, scale: 2, default: "0.0"
    t.boolean "disable_auto_invoice"
    t.boolean "separate_out_sales_tax_on_invoices", default: false
    t.decimal "service_fee", precision: 8, scale: 2, default: "0.0"
    t.index ["company_id"], name: "billings_company_id_idx"
  end

  create_table "business_addresses", force: :cascade do |t|
    t.string "name", limit: 510
    t.decimal "rating", precision: 8, scale: 2, default: "0.0"
    t.string "formatted_phone_number", limit: 510
    t.string "formatted_address", limit: 510
    t.string "vicinity", limit: 510
    t.integer "price_level", default: 0
    t.string "url", limit: 510
    t.string "website", limit: 510
    t.text "weekday_text"
    t.string "business_type", limit: 510
    t.string "lat", limit: 510
    t.string "lng", limit: 510
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "review_count", default: 0
  end

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string "data_file_name", limit: 510, null: false
    t.string "data_content_type", limit: 510
    t.integer "data_file_size"
    t.string "type", limit: 60
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "companies", force: :cascade do |t|
    t.integer "status", default: 0
    t.integer "parent_status", default: 0
    t.string "name", limit: 510
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "user_meal_budget", precision: 8, scale: 2, default: "0.0"
    t.decimal "markup", precision: 8, scale: 2, default: "0.0"
    t.integer "reduced_markup", default: 0
    t.boolean "reduced_markup_check"
    t.integer "user_copay", default: 0
    t.decimal "copay_amount", precision: 15, scale: 2, default: "0.0"
    t.string "image", limit: 510
    t.integer "show_remaining_budget", default: 1
    t.boolean "enable_grouping_orders"
    t.text "site_survey"
    t.integer "entree", default: 0
    t.integer "appetizers", default: 0
    t.integer "dessert", default: 0
    t.integer "sides", default: 0
    t.decimal "buffet_per_user_budget", precision: 8, scale: 4, default: "0.0"
    t.decimal "buffet_addons_markup", precision: 8, scale: 4, default: "30.0"
    t.boolean "enable_marketplace", default: false
    t.text "delivery_notes"
    t.string "time_zone"
    t.integer "parent_company_id"
    t.boolean "enable_saas", default: false
    t.boolean "allow_users_to_onboard_without_admin_approval", default: false
    t.index ["deleted_at"], name: "index_companies_on_deleted_at"
  end

  create_table "companies_schedules", force: :cascade do |t|
    t.bigint "address_id"
    t.bigint "labels_seq_id"
    t.bigint "cuisines_sequence_id"
    t.bigint "addresses_cuisineslist_id"
    t.date "delivery_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cuisineslist_id"
    t.bigint "restaurant_address_id"
    t.index ["address_id"], name: "index_companies_schedules_on_address_id"
    t.index ["addresses_cuisineslist_id"], name: "index_companies_schedules_on_addresses_cuisineslist_id"
    t.index ["cuisines_sequence_id"], name: "index_companies_schedules_on_cuisines_sequence_id"
    t.index ["labels_seq_id"], name: "index_companies_schedules_on_labels_seq_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "address_id"
    t.bigint "addresses_id"
    t.string "name", limit: 510, null: false
    t.string "phone_number", limit: 510
    t.string "email", limit: 510
    t.string "fax", limit: 510
    t.boolean "email_label_check"
    t.boolean "fax_summary_check"
    t.boolean "email_summary_check"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "send_text_reminders", default: true
    t.index ["address_id"], name: "contacts_address_id_idx"
    t.index ["addresses_id"], name: "contacts_addresses_id_idx"
    t.index ["deleted_at"], name: "index_contacts_on_deleted_at"
  end

  create_table "cuisines", force: :cascade do |t|
    t.string "name", limit: 510
    t.text "description"
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_cuisines_on_deleted_at"
  end

  create_table "cuisines_menus", force: :cascade do |t|
    t.bigint "cuisine_id"
    t.bigint "runningmenu_id"
    t.bigint "latest_version_id"
    t.index ["cuisine_id"], name: "cuisines_menus_cuisine_id_idx"
    t.index ["runningmenu_id"], name: "cuisines_menus_runningmenu_id_idx"
  end

  create_table "cuisines_recurring_menus", force: :cascade do |t|
    t.bigint "cuisine_id"
    t.bigint "recurring_scheduler_id"
    t.integer "status", default: 0
    t.index ["cuisine_id"], name: "index_cuisines_recurring_menus_on_cuisine_id"
    t.index ["recurring_scheduler_id"], name: "index_cuisines_recurring_menus_on_recurring_scheduler_id"
  end

  create_table "cuisines_requests", force: :cascade do |t|
    t.bigint "cuisine_id"
    t.bigint "runningmenu_request_id"
    t.bigint "runningmenu_id"
    t.index ["cuisine_id"], name: "cuisines_requests_cuisine_id_idx"
    t.index ["runningmenu_request_id"], name: "cuisines_requests_runningmenu_request_id_idx"
  end

  create_table "cuisines_restaurants", force: :cascade do |t|
    t.bigint "cuisine_id"
    t.bigint "restaurant_id"
    t.index ["cuisine_id"], name: "cuisines_restaurants_cuisine_id_idx"
    t.index ["restaurant_id"], name: "cuisines_restaurants_restaurant_id_idx"
  end

  create_table "cuisines_sequences", force: :cascade do |t|
    t.bigint "cuisineslist_id"
    t.bigint "labels_seq_id"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cuisineslist_id"], name: "index_cuisines_sequences_on_cuisineslist_id"
    t.index ["labels_seq_id"], name: "index_cuisines_sequences_on_labels_seq_id"
  end

  create_table "cuisines_users", force: :cascade do |t|
    t.bigint "cuisine_id"
    t.bigint "user_id"
    t.index ["cuisine_id"], name: "cuisines_users_cuisine_id_idx"
    t.index ["user_id"], name: "cuisines_users_user_id_idx"
  end

  create_table "cuisineslists", force: :cascade do |t|
    t.string "name"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "menu_type", default: 0
  end

  create_table "dashboard_metrics", force: :cascade do |t|
    t.integer "metric_type"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dietaries", force: :cascade do |t|
    t.string "name", limit: 510
    t.text "description"
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "draft_id"
    t.boolean "enable_user_to_filter", default: true
    t.text "logo"
    t.text "alt_logo"
    t.index ["deleted_at"], name: "index_dietaries_on_deleted_at"
  end

  create_table "dietaries_fooditems", id: false, force: :cascade do |t|
    t.bigint "dietary_id"
    t.bigint "fooditem_id"
    t.index ["dietary_id"], name: "dietaries_fooditems_dietary_id_idx"
    t.index ["fooditem_id"], name: "dietaries_fooditems_fooditem_id_idx"
  end

  create_table "dietaries_gfooditems", id: false, force: :cascade do |t|
    t.bigint "dietary_id"
    t.bigint "gfooditem_id"
    t.index ["dietary_id"], name: "dietaries_gfooditems_dietary_id_idx"
    t.index ["gfooditem_id"], name: "dietaries_gfooditems_gfooditem_id_idx"
  end

  create_table "dietaries_goptions", id: false, force: :cascade do |t|
    t.bigint "dietary_id"
    t.bigint "goption_id"
    t.index ["dietary_id"], name: "dietaries_goptions_dietary_id_idx"
    t.index ["goption_id"], name: "dietaries_goptions_goption_id_idx"
  end

  create_table "dietaries_options", id: false, force: :cascade do |t|
    t.bigint "dietary_id"
    t.bigint "option_id"
    t.index ["dietary_id"], name: "dietaries_options_dietary_id_idx"
    t.index ["option_id"], name: "dietaries_options_option_id_idx"
  end

  create_table "dietaries_users", force: :cascade do |t|
    t.bigint "dietary_id"
    t.bigint "user_id"
    t.index ["dietary_id"], name: "dietaries_users_dietary_id_idx"
    t.index ["user_id"], name: "dietaries_users_user_id_idx"
  end

  create_table "dishsize_fooditems", force: :cascade do |t|
    t.bigint "fooditem_id"
    t.bigint "dishsize_id"
    t.decimal "price", precision: 8, scale: 4, default: "0.0"
    t.index ["dishsize_id"], name: "dishsize_fooditems_dishsize_id_idx"
    t.index ["fooditem_id"], name: "dishsize_fooditems_fooditem_id_idx"
  end

  create_table "dishsizes", force: :cascade do |t|
    t.bigint "address_id"
    t.string "title", limit: 510
    t.text "description"
    t.integer "serve_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.integer "parent_status", default: 0
  end

  create_table "distances", force: :cascade do |t|
    t.float "lat0"
    t.float "long0"
    t.float "lat1"
    t.float "long1"
    t.integer "unit", default: 0
    t.decimal "distance", precision: 8, scale: 2, default: "0.0"
  end

  create_table "driver_shifts", force: :cascade do |t|
    t.bigint "driver_id"
    t.string "label", limit: 510
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "drivers", force: :cascade do |t|
    t.string "first_name", limit: 510
    t.string "last_name", limit: 510
    t.string "email", limit: 510
    t.string "phone_number", limit: 510
    t.integer "status", default: 0
    t.string "worker_id", limit: 510
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "car", limit: 510
    t.string "car_color", limit: 510
    t.string "car_licence_plate", limit: 510
    t.string "image", limit: 510
    t.bigint "restaurant_address_id"
    t.string "onfleet_team_id"
    t.index ["restaurant_address_id"], name: "index_drivers_on_restaurant_address_id"
  end

  create_table "dynamic_sections", force: :cascade do |t|
    t.bigint "runningmenu_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "icon", default: "fas fa-heart"
    t.index ["runningmenu_id"], name: "index_dynamic_sections_on_runningmenu_id"
  end

  create_table "email_logs", force: :cascade do |t|
    t.string "subject", limit: 510
    t.string "sender", limit: 510
    t.string "recipient", limit: 510
    t.text "cc"
    t.datetime "sent_at"
    t.datetime "failed_at"
    t.text "body"
    t.integer "status", default: 0
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "attachment", limit: 510
    t.string "attachment_file_name", limit: 510
    t.string "job_id"
    t.index ["cc"], name: "index_email_logs_on_cc"
    t.index ["recipient"], name: "index_email_logs_on_recipient"
    t.index ["sender"], name: "index_email_logs_on_sender"
    t.index ["status"], name: "index_email_logs_on_status"
    t.index ["subject"], name: "index_email_logs_on_subject"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "company_id"
    t.string "favoritable_type"
    t.bigint "favoritable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_favorites_on_company_id"
    t.index ["favoritable_id", "favoritable_type"], name: "index_favorites_on_favoritable_id_and_favoritable_type"
    t.index ["favoritable_type", "favoritable_id"], name: "index_favorites_on_favoritable_type_and_favoritable_id"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "faxlogs", force: :cascade do |t|
    t.string "from", limit: 510
    t.string "to", limit: 510
    t.string "media_url", limit: 510
    t.string "sid", limit: 510
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "file_name", limit: 510
    t.datetime "retry_time"
    t.integer "tries", default: 0
    t.string "fax_job_id"
  end

  create_table "fieldoptions", force: :cascade do |t|
    t.bigint "field_id"
    t.string "name", limit: 510
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.integer "position"
    t.index ["deleted_at"], name: "index_fieldoptions_on_deleted_at"
    t.index ["field_id"], name: "fieldoptions_field_id_idx"
  end

  create_table "fields", force: :cascade do |t|
    t.bigint "company_id"
    t.integer "field_type", default: 0
    t.string "name", limit: 510
    t.integer "required", default: 0
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.integer "position"
    t.index ["company_id"], name: "fields_company_id_idx"
    t.index ["deleted_at"], name: "index_fields_on_deleted_at"
  end

  create_table "fooditems", force: :cascade do |t|
    t.integer "parent_id"
    t.bigint "menu_id"
    t.bigint "gfooditem_id"
    t.string "name", limit: 510
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.text "description"
    t.integer "calories", default: 0, null: false
    t.integer "spicy", default: 0
    t.integer "best_seller", default: 0
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image", limit: 510
    t.decimal "price", precision: 8, scale: 2, default: "0.0"
    t.decimal "gross_price", precision: 8, scale: 2, default: "0.0"
    t.decimal "rating_total", precision: 15, scale: 2, default: "0.0"
    t.integer "rating_count", default: 0
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0"
    t.integer "position"
    t.boolean "skip_markup"
    t.string "notes_to_restaurant", limit: 510
    t.boolean "ignore_budget"
    t.integer "draft_id"
    t.string "file_url"
    t.index ["deleted_at"], name: "index_fooditems_on_deleted_at"
    t.index ["gfooditem_id"], name: "fooditems_gfooditem_id_idx"
    t.index ["menu_id"], name: "fooditems_menu_id_idx"
  end

  create_table "fooditems_ingredients", id: false, force: :cascade do |t|
    t.bigint "fooditem_id"
    t.bigint "ingredient_id"
    t.index ["fooditem_id"], name: "fooditems_ingredients_fooditem_id_idx"
    t.index ["ingredient_id"], name: "fooditems_ingredients_ingredient_id_idx"
  end

  create_table "fooditems_optionsets", id: false, force: :cascade do |t|
    t.bigint "fooditem_id"
    t.bigint "optionset_id"
    t.index ["fooditem_id"], name: "fooditems_optionsets_fooditem_id_idx"
    t.index ["optionset_id"], name: "fooditems_optionsets_optionset_id_idx"
  end

  create_table "fooditems_sections", id: false, force: :cascade do |t|
    t.bigint "section_id"
    t.bigint "fooditem_id"
    t.index ["fooditem_id"], name: "fooditems_sections_fooditem_id_idx"
    t.index ["section_id"], name: "fooditems_sections_section_id_idx"
  end

  create_table "fresh_desk_logs", force: :cascade do |t|
    t.integer "ticketidentity"
    t.integer "widget_type"
    t.string "name", limit: 510
    t.string "portal_name", limit: 510
    t.string "requester", limit: 510
    t.string "email", limit: 510
    t.string "subject", limit: 510
    t.text "description"
    t.text "attachment"
    t.string "ticket_url", limit: 510
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "gfooditems", force: :cascade do |t|
    t.integer "parent_id"
    t.bigint "gmenu_id"
    t.string "name", limit: 510
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.text "description"
    t.integer "calories", default: 0, null: false
    t.integer "spicy", default: 0
    t.integer "best_seller", default: 0
    t.integer "item_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image", limit: 510
    t.string "old_image", limit: 510
    t.decimal "price", precision: 8, scale: 2, default: "0.0"
    t.integer "position"
    t.boolean "skip_markup"
    t.string "notes_to_restaurant", limit: 510
    t.boolean "ignore_budget"
    t.index ["deleted_at"], name: "index_gfooditems_on_deleted_at"
    t.index ["gmenu_id"], name: "gfooditems_gmenu_id_idx"
  end

  create_table "gfooditems_goptionsets", id: false, force: :cascade do |t|
    t.bigint "gfooditem_id"
    t.bigint "goptionset_id"
    t.index ["gfooditem_id"], name: "gfooditems_goptionsets_gfooditem_id_idx"
    t.index ["goptionset_id"], name: "gfooditems_goptionsets_goptionset_id_idx"
  end

  create_table "gfooditems_gsections", id: false, force: :cascade do |t|
    t.bigint "gsection_id"
    t.bigint "gfooditem_id"
    t.index ["gfooditem_id"], name: "gfooditems_gsections_gfooditem_id_idx"
    t.index ["gsection_id"], name: "gfooditems_gsections_gsection_id_idx"
  end

  create_table "gfooditems_ingredients", id: false, force: :cascade do |t|
    t.bigint "gfooditem_id"
    t.bigint "ingredient_id"
    t.index ["gfooditem_id"], name: "gfooditems_ingredients_gfooditem_id_idx"
    t.index ["ingredient_id"], name: "gfooditems_ingredients_ingredient_id_idx"
  end

  create_table "gmenus", force: :cascade do |t|
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.integer "parent_id"
    t.bigint "restaurant_id"
    t.integer "menu_type", default: 0, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_gmenus_on_deleted_at"
    t.index ["restaurant_id"], name: "gmenus_restaurant_id_idx"
  end

  create_table "goptions", force: :cascade do |t|
    t.integer "parent_id"
    t.bigint "goptionset_id"
    t.string "description", limit: 510
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.integer "calories", default: 0, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price", precision: 8, scale: 2, default: "0.0"
    t.integer "position"
    t.index ["deleted_at"], name: "index_goptions_on_deleted_at"
    t.index ["goptionset_id"], name: "goptions_goptionset_id_idx"
  end

  create_table "goptions_ingredients", id: false, force: :cascade do |t|
    t.bigint "goption_id"
    t.bigint "ingredient_id"
    t.index ["goption_id"], name: "goptions_ingredients_goption_id_idx"
    t.index ["ingredient_id"], name: "goptions_ingredients_ingredient_id_idx"
  end

  create_table "goptionsets", force: :cascade do |t|
    t.integer "parent_id"
    t.bigint "gmenu_id"
    t.integer "choice_type"
    t.string "name", limit: 510
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.integer "required", default: 0
    t.integer "start_limit", default: 0, null: false
    t.integer "end_limit", default: 0, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["deleted_at"], name: "index_goptionsets_on_deleted_at"
    t.index ["gmenu_id"], name: "goptionsets_gmenu_id_idx"
  end

  create_table "gsections", force: :cascade do |t|
    t.integer "parent_id"
    t.bigint "gmenu_id"
    t.string "name", limit: 510
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.text "description"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["deleted_at"], name: "index_gsections_on_deleted_at"
    t.index ["gmenu_id"], name: "gsections_gmenu_id_idx"
  end

  create_table "guests", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
  end

  create_table "holidays", force: :cascade do |t|
    t.bigint "address_id"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_holidays_on_address_id"
  end

  create_table "images", force: :cascade do |t|
    t.string "image"
    t.string "imageable_type"
    t.bigint "imageable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["imageable_type", "imageable_id"], name: "index_images_on_imageable_type_and_imageable_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "name", limit: 510
    t.text "description"
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "draft_id"
    t.boolean "enable_user_to_filter", default: true
    t.text "logo"
    t.text "alt_logo"
    t.index ["deleted_at"], name: "index_ingredients_on_deleted_at"
  end

  create_table "ingredients_options", id: false, force: :cascade do |t|
    t.bigint "ingredient_id"
    t.bigint "option_id"
    t.index ["ingredient_id"], name: "ingredients_options_ingredient_id_idx"
    t.index ["option_id"], name: "ingredients_options_option_id_idx"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "invoice_number"
    t.text "bill_to"
    t.text "ship_to"
    t.text "payment_terms"
    t.datetime "ship_date"
    t.datetime "due_date"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "delivery_fee", precision: 8, scale: 2, default: "0.0"
    t.datetime "from"
    t.datetime "to"
    t.bigint "company_id"
    t.decimal "total_amount", precision: 8, scale: 2, default: "0.0"
    t.decimal "total_discount", precision: 8, scale: 2, default: "0.0"
    t.decimal "total_amount_due", precision: 8, scale: 2, default: "0.0"
    t.decimal "total_amount_due_qb", precision: 8, scale: 2, default: "0.0"
    t.bigint "restaurant_id"
    t.bigint "restaurant_address_id"
    t.integer "delivery_type", default: 0
    t.boolean "charged_cc", default: false
    t.datetime "paid_date"
    t.decimal "delivery_fee_total", precision: 8, scale: 2, default: "0.0"
    t.decimal "sales_tax", precision: 8, scale: 2, default: "0.0"
    t.decimal "service_fee", precision: 8, scale: 2, default: "0.0"
    t.index ["company_id"], name: "index_invoices_on_company_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number"
    t.index ["restaurant_address_id"], name: "index_invoices_on_restaurant_address_id"
    t.index ["restaurant_id"], name: "index_invoices_on_restaurant_id"
  end

  create_table "labels_seqs", force: :cascade do |t|
    t.bigint "sequence_id"
    t.string "title"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sequence_id"], name: "index_labels_seqs_on_sequence_id"
  end

  create_table "line_items", force: :cascade do |t|
    t.bigint "invoice_id"
    t.integer "quantity"
    t.string "item", limit: 510
    t.decimal "unit_price", precision: 8, scale: 2, default: "0.0"
    t.decimal "amount", precision: 8, scale: 2, default: "0.0"
    t.decimal "discount", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "logs_attachments", force: :cascade do |t|
    t.bigint "email_log_id"
    t.string "attachment", limit: 510
    t.string "attachment_file_name", limit: 510
    t.index ["email_log_id"], name: "logs_attachments_email_log_id_idx"
  end

  create_table "menus", force: :cascade do |t|
    t.integer "parent_id"
    t.bigint "address_id"
    t.bigint "gmenu_id"
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.integer "menu_type", default: 0, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "request_status", default: 0
    t.integer "draft_id"
    t.index ["address_id"], name: "menus_address_id_idx"
    t.index ["deleted_at"], name: "index_menus_on_deleted_at"
    t.index ["gmenu_id"], name: "menus_gmenu_id_idx"
  end

  create_table "nutritional_facts", force: :cascade do |t|
    t.bigint "nutrition_id"
    t.string "factable_type"
    t.bigint "factable_id"
    t.decimal "value", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["factable_type", "factable_id"], name: "index_nutritional_facts_on_factable_type_and_factable_id"
    t.index ["nutrition_id"], name: "index_nutritional_facts_on_nutrition_id"
  end

  create_table "nutritions", force: :cascade do |t|
    t.string "name"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "options", force: :cascade do |t|
    t.integer "parent_id"
    t.bigint "optionset_id"
    t.bigint "goption_id"
    t.string "description", limit: 510
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.integer "calories", default: 0, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price", precision: 8, scale: 2, default: "0.0"
    t.integer "position"
    t.integer "draft_id"
    t.index ["deleted_at"], name: "index_options_on_deleted_at"
    t.index ["goption_id"], name: "options_goption_id_idx"
    t.index ["optionset_id"], name: "options_optionset_id_idx"
  end

  create_table "options_orders", force: :cascade do |t|
    t.bigint "optionsets_order_id"
    t.bigint "option_id"
    t.bigint "order_id"
    t.decimal "price", precision: 8, scale: 2, default: "0.0"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_options_orders_on_deleted_at"
    t.index ["option_id"], name: "options_orders_option_id_idx"
    t.index ["optionsets_order_id"], name: "options_orders_optionsets_order_id_idx"
    t.index ["order_id"], name: "options_orders_order_id_idx"
  end

  create_table "optionsets", force: :cascade do |t|
    t.integer "parent_id"
    t.bigint "menu_id"
    t.bigint "goptionset_id"
    t.string "name", limit: 510
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.integer "required", default: 0
    t.integer "start_limit", default: 0, null: false
    t.integer "end_limit", default: 0, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.integer "draft_id"
    t.index ["deleted_at"], name: "index_optionsets_on_deleted_at"
    t.index ["goptionset_id"], name: "optionsets_goptionset_id_idx"
    t.index ["menu_id"], name: "optionsets_menu_id_idx"
  end

  create_table "optionsets_orders", force: :cascade do |t|
    t.bigint "optionset_id"
    t.bigint "order_id"
    t.integer "required", default: 0
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_optionsets_orders_on_deleted_at"
    t.index ["optionset_id"], name: "optionsets_orders_optionset_id_idx"
    t.index ["order_id"], name: "optionsets_orders_order_id_idx"
  end

  create_table "order_change_logs", force: :cascade do |t|
    t.bigint "order_id"
    t.integer "order_quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_change_logs_on_order_id"
  end

  create_table "orderfields", force: :cascade do |t|
    t.bigint "order_id"
    t.bigint "company_id"
    t.bigint "field_id"
    t.bigint "fieldoption_id"
    t.integer "field_type", default: 0
    t.string "value", limit: 510
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "orderfields_company_id_idx"
    t.index ["field_id"], name: "orderfields_field_id_idx"
    t.index ["fieldoption_id"], name: "orderfields_fieldoption_id_idx"
    t.index ["order_id"], name: "orderfields_order_id_idx"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "restaurant_id"
    t.integer "restaurant_address_id"
    t.bigint "company_id"
    t.bigint "address_id"
    t.bigint "runningmenu_id"
    t.bigint "dishsize_id"
    t.datetime "ordered_at"
    t.datetime "cancelled_time"
    t.integer "order_type", default: 0
    t.bigint "fooditem_id"
    t.bigint "quantity"
    t.decimal "price", precision: 8, scale: 2, default: "0.0"
    t.decimal "company_price", precision: 8, scale: 2, default: "0.0"
    t.decimal "user_price", precision: 8, scale: 2, default: "0.0"
    t.decimal "site_price", precision: 8, scale: 2, default: "0.0"
    t.decimal "total_price", precision: 8, scale: 2, default: "0.0"
    t.integer "status", default: 0
    t.integer "parent_status", default: 0
    t.decimal "rating", precision: 3, scale: 2, default: "0.0"
    t.string "remarks", limit: 510
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "invoice_id"
    t.decimal "discount", precision: 10, default: "0"
    t.bigint "latest_version_id"
    t.bigint "share_meeting_id"
    t.bigint "restaurant_billing_id"
    t.boolean "user_markup", default: false
    t.text "group"
    t.decimal "food_price", precision: 8, scale: 2, default: "0.0"
    t.decimal "food_price_total", precision: 8, scale: 2, default: "0.0"
    t.integer "number_of_meals", default: 0
    t.decimal "sales_tax", precision: 12, scale: 6, default: "0.0"
    t.decimal "restaurant_commission", precision: 12, scale: 6, default: "0.0"
    t.decimal "restaurant_payout", precision: 12, scale: 6, default: "0.0"
    t.decimal "sales_tax_rate", precision: 8, scale: 4, default: "0.0"
    t.string "formatted_group"
    t.decimal "user_paid", precision: 8, scale: 2, default: "0.0"
    t.decimal "company_paid", precision: 8, scale: 2, default: "0.0"
    t.bigint "guest_id"
    t.integer "new_items_in_last24_hours", default: 0
    t.index ["address_id"], name: "orders_address_id_idx"
    t.index ["company_id"], name: "orders_company_id_idx"
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["deleted_at"], name: "index_orders_on_deleted_at"
    t.index ["dishsize_id"], name: "orders_dishsize_id_idx"
    t.index ["fooditem_id"], name: "orders_fooditem_id_idx"
    t.index ["guest_id"], name: "index_orders_on_guest_id"
    t.index ["invoice_id", "status"], name: "index_orders_on_invoice_id_and_status"
    t.index ["invoice_id"], name: "index_orders_on_invoice_id"
    t.index ["restaurant_address_id"], name: "index_orders_on_restaurant_address_id"
    t.index ["restaurant_id"], name: "orders_restaurant_id_idx"
    t.index ["runningmenu_id"], name: "orders_runningmenu_id_idx"
    t.index ["updated_at"], name: "index_orders_on_updated_at"
    t.index ["user_id"], name: "orders_user_id_idx"
  end

  create_table "orders_payment_logs", id: false, force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "payment_log_id", null: false
  end

  create_table "payment_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "company_id"
    t.decimal "amount", precision: 8, scale: 2, default: "0.0"
    t.integer "payment_gateway"
    t.integer "status"
    t.text "message"
    t.string "email", limit: 510
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_id", limit: 510
    t.decimal "refund_amount", precision: 8, scale: 2, default: "0.0"
    t.datetime "refund_date"
    t.integer "refund_by"
    t.decimal "refunded_amount", precision: 8, scale: 2, default: "0.0"
    t.boolean "sales_receipt", default: false
    t.index ["company_id"], name: "payment_logs_company_id_idx"
  end

  create_table "quickbook_logs", force: :cascade do |t|
    t.integer "upload_identity"
    t.integer "upload_type"
    t.integer "event_type"
    t.integer "quickbook_identity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ratings", force: :cascade do |t|
    t.integer "user_id"
    t.bigint "runningmenu_id"
    t.bigint "order_id"
    t.text "comment"
    t.integer "rating_value"
    t.string "ratingable_type", limit: 510
    t.bigint "ratingable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.bigint "restaurant_address_id"
    t.integer "status", default: 0
    t.integer "parent_status", default: 0
    t.index ["order_id"], name: "ratings_order_id_idx"
    t.index ["restaurant_address_id"], name: "index_ratings_on_restaurant_address_id"
    t.index ["restaurant_id"], name: "index_ratings_on_restaurant_id"
    t.index ["runningmenu_id"], name: "ratings_runningmenu_id_idx"
  end

  create_table "recurring_dynamic_sections", force: :cascade do |t|
    t.bigint "recurring_scheduler_id"
    t.string "name"
    t.string "icon", default: "fas fa-heart"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recurring_scheduler_id"], name: "index_recurring_dynamic_sections_on_recurring_scheduler_id"
  end

  create_table "recurring_schedulers", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "company_id"
    t.bigint "address_id"
    t.bigint "driver_id"
    t.integer "runningmenu_type", default: 0
    t.integer "menu_type", default: 0
    t.integer "status", default: 1
    t.integer "parent_status", default: 0
    t.boolean "hide_meeting"
    t.text "special_request"
    t.string "runningmenu_name"
    t.decimal "per_meal_budget"
    t.string "deleted_cuisines"
    t.boolean "notify_admin"
    t.boolean "approve_ban_restaurant"
    t.integer "orders_count"
    t.integer "per_user_copay"
    t.decimal "per_user_copay_amount"
    t.datetime "startdate"
    t.boolean "monday", default: false
    t.boolean "tuesday", default: false
    t.boolean "wednesday", default: false
    t.boolean "thursday", default: false
    t.boolean "friday", default: false
    t.boolean "saturday", default: false
    t.boolean "sunday", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "bev_rest_deleted", default: false
    t.integer "recurrence_days"
    t.text "delivery_instructions"
    t.integer "first_restaurant"
    t.integer "cutoff_hours", default: 22
    t.integer "cutoff_minutes", default: 0
    t.integer "admin_cutoff_hours", default: 22
    t.integer "admin_cutoff_minutes", default: 0
    t.integer "pickup_hours", default: 1
    t.integer "pickup_minutes", default: 15
    t.index ["address_id"], name: "index_recurring_schedulers_on_address_id"
    t.index ["company_id"], name: "index_recurring_schedulers_on_company_id"
    t.index ["driver_id"], name: "index_recurring_schedulers_on_driver_id"
    t.index ["user_id"], name: "index_recurring_schedulers_on_user_id"
  end

  create_table "rep_boxes", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "address_id"
    t.decimal "average_food_rating", precision: 8, scale: 2, default: "0.0"
    t.decimal "average_service_rating", precision: 8, scale: 2, default: "0.0"
    t.decimal "on_time_deliveries", default: "0.0"
    t.bigint "meals", default: 0
    t.bigint "vendors", default: 0
    t.text "cuisines", default: [], array: true
    t.date "dated_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_rep_boxes_on_address_id"
    t.index ["company_id"], name: "index_rep_boxes_on_company_id"
  end

  create_table "rep_budget_analyses", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "address_id"
    t.string "company_name"
    t.string "company_address"
    t.bigint "quantity"
    t.decimal "food_cost", precision: 8, scale: 2, default: "0.0"
    t.decimal "food_cost_avg", precision: 8, scale: 2, default: "0.0"
    t.decimal "service_cost_avg", precision: 8, scale: 2, default: "0.0"
    t.decimal "budget", precision: 8, scale: 2, default: "0.0"
    t.date "dated_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_rep_budget_analyses_on_address_id"
    t.index ["company_id"], name: "index_rep_budget_analyses_on_company_id"
  end

  create_table "rep_charts", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "address_id"
    t.decimal "expense", precision: 8, scale: 2, default: "0.0"
    t.decimal "saving", precision: 8, scale: 2, default: "0.0"
    t.bigint "meals"
    t.date "dated_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_rep_charts_on_address_id"
    t.index ["company_id"], name: "index_rep_charts_on_company_id"
  end

  create_table "rep_nutritions", force: :cascade do |t|
    t.string "name"
    t.bigint "dietary_id"
    t.bigint "company_id"
    t.bigint "address_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_rep_nutritions_on_address_id"
    t.index ["company_id"], name: "index_rep_nutritions_on_company_id"
    t.index ["dietary_id"], name: "index_rep_nutritions_on_dietary_id"
    t.index ["user_id"], name: "index_rep_nutritions_on_user_id"
  end

  create_table "rep_satisfactions", force: :cascade do |t|
    t.string "name"
    t.bigint "dietary_id"
    t.bigint "company_id"
    t.bigint "address_id"
    t.date "dated_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_rep_satisfactions_on_address_id"
    t.index ["company_id"], name: "index_rep_satisfactions_on_company_id"
    t.index ["dietary_id"], name: "index_rep_satisfactions_on_dietary_id"
  end

  create_table "rep_vendors", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "address_id"
    t.bigint "restaurant_id"
    t.string "name"
    t.string "company_name"
    t.string "cuisine"
    t.decimal "rating", precision: 8, scale: 2, default: "0.0"
    t.decimal "total_spent", precision: 8, scale: 2, default: "0.0"
    t.decimal "number_of_meals", precision: 8, scale: 2, default: "0.0"
    t.date "dated_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_rep_vendors_on_address_id"
    t.index ["company_id"], name: "index_rep_vendors_on_company_id"
    t.index ["restaurant_id"], name: "index_rep_vendors_on_restaurant_id"
  end

  create_table "reports", force: :cascade do |t|
    t.string "name"
    t.integer "report_type"
    t.integer "scheduled_period"
    t.integer "scheduled_time"
    t.boolean "enable_error_logging", default: false
  end

  create_table "reports_users", id: false, force: :cascade do |t|
    t.bigint "report_id", null: false
    t.bigint "user_id", null: false
    t.index ["report_id", "user_id"], name: "index_reports_users_on_report_id_and_user_id"
  end

  create_table "restaurant_billings", force: :cascade do |t|
    t.bigint "restaurant_id"
    t.bigint "address_id"
    t.integer "payment_status", default: 0
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "due_date"
    t.decimal "tips", precision: 8, scale: 2, default: "0.0"
    t.decimal "credit_card_fees", precision: 8, scale: 2, default: "0.0"
    t.integer "billing_number"
    t.integer "payment_method", default: 0
    t.date "paid_on"
    t.datetime "orders_from"
    t.datetime "orders_to"
    t.decimal "commission", precision: 8, scale: 2, default: "0.0"
    t.decimal "food_total", precision: 8, scale: 2, default: "0.0"
    t.decimal "sales_tax", precision: 8, scale: 2, default: "0.0"
    t.integer "billing_type", default: 0
    t.bigint "quantity_total", default: 0
    t.decimal "payout_total", precision: 8, scale: 2, default: "0.0"
    t.string "final_status_job_id"
    t.string "due_status_job_id"
    t.string "stripe_payout_id"
  end

  create_table "restaurant_shifts", force: :cascade do |t|
    t.bigint "address_id"
    t.string "label", limit: 510
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "closed", default: false
  end

  create_table "restaurants", force: :cascade do |t|
    t.string "name", limit: 510
    t.integer "lunch_order_capacity"
    t.integer "dinner_order_capacity"
    t.string "notes", limit: 510
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.integer "vendor_id"
    t.integer "migrated", default: 0
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "preferred_vendor"
    t.integer "request_status", default: 0
    t.integer "draft_id"
    t.string "time_zone"
    t.decimal "rating_total", precision: 8, scale: 2, default: "0.0"
    t.integer "rating_count", default: 0
    t.decimal "average_rating", precision: 8, scale: 2, default: "0.0"
    t.index ["deleted_at"], name: "index_restaurants_on_deleted_at"
  end

  create_table "runningmenu_requests", force: :cascade do |t|
    t.integer "runningmenu_request_type", null: false
    t.integer "menu_type", default: 0
    t.bigint "user_id"
    t.bigint "company_id"
    t.bigint "address_id"
    t.datetime "delivery_at"
    t.time "end_time"
    t.integer "recurring", default: 0
    t.integer "orders", default: 0
    t.integer "monday", default: 0
    t.integer "tuesday", default: 0
    t.integer "wednesday", default: 0
    t.integer "thursday", default: 0
    t.integer "friday", default: 0
    t.integer "status", default: 0
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "schedular_check"
    t.text "special_request"
    t.index ["address_id"], name: "runningmenu_requests_address_id_idx"
    t.index ["company_id"], name: "runningmenu_requests_company_id_idx"
    t.index ["user_id"], name: "runningmenu_requests_user_id_idx"
  end

  create_table "runningmenufields", force: :cascade do |t|
    t.bigint "runningmenu_id"
    t.bigint "field_id"
    t.bigint "fieldoption_id"
    t.integer "field_type", default: 0
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "latest_version_id"
    t.bigint "recurring_scheduler_id"
    t.index ["field_id"], name: "runningmenufields_field_id_idx"
    t.index ["fieldoption_id"], name: "runningmenufields_fieldoption_id_idx"
    t.index ["recurring_scheduler_id"], name: "index_runningmenufields_on_recurring_scheduler_id"
    t.index ["runningmenu_id"], name: "runningmenufields_runningmenu_id_idx"
  end

  create_table "runningmenurequestfields", force: :cascade do |t|
    t.bigint "runningmenu_request_id"
    t.bigint "field_id"
    t.bigint "fieldoption_id"
    t.integer "field_type", default: 0
    t.string "value", limit: 510
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "runningmenu_id"
    t.index ["field_id"], name: "runningmenurequestfields_field_id_idx"
    t.index ["fieldoption_id"], name: "runningmenurequestfields_fieldoption_id_idx"
    t.index ["runningmenu_request_id"], name: "runningmenurequestfields_runningmenu_request_id_idx"
  end

  create_table "runningmenus", force: :cascade do |t|
    t.integer "runningmenu_type", default: 0, null: false
    t.string "task_id", limit: 510
    t.string "pickup_task_id", limit: 510
    t.boolean "task_completed"
    t.bigint "company_id"
    t.bigint "address_id"
    t.datetime "delivery_at"
    t.datetime "activation_at"
    t.datetime "cutoff_at"
    t.datetime "admin_cutoff_at"
    t.integer "menu_type", default: 0
    t.integer "orders_count", default: 0
    t.integer "status", default: 1
    t.integer "parent_status", default: 0
    t.boolean "hide_meeting"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "special_request"
    t.time "end_time"
    t.string "runningmenu_name", limit: 510
    t.decimal "per_meal_budget", precision: 8, scale: 2, default: "0.0"
    t.bigint "user_id"
    t.bigint "latest_version_id"
    t.string "deleted_cuisines", limit: 510
    t.string "share_token", limit: 510
    t.text "cancel_reason"
    t.datetime "cancelled_at"
    t.bigint "cancelled_by_id"
    t.decimal "rating_total", precision: 8, scale: 2, default: "0.0"
    t.integer "rating_count", default: 0
    t.decimal "average_rating", precision: 8, scale: 2, default: "0.0"
    t.boolean "auto_scheduling"
    t.bigint "driver_id"
    t.boolean "notify_admin"
    t.boolean "csv_imported"
    t.boolean "approve_ban_restaurant"
    t.integer "per_user_copay", default: 0
    t.decimal "per_user_copay_amount", precision: 15, scale: 2, default: "0.0"
    t.integer "entree", default: 0
    t.integer "appetizers", default: 0
    t.integer "dessert", default: 0
    t.integer "sides", default: 0
    t.decimal "buffet_per_user_budget", precision: 8, scale: 4, default: "0.0"
    t.integer "task_status", default: 0
    t.integer "pickup_task_status", default: 0
    t.integer "arriving_at"
    t.datetime "completion_time"
    t.boolean "marketplace", default: false
    t.text "delivery_instructions"
    t.string "slug"
    t.integer "delivery_type", default: 0
    t.boolean "enqueued_for_invoice", default: false
    t.datetime "approved_at"
    t.string "job_id"
    t.string "cutoff_reached_job_id"
    t.string "admin_cutoff_reached_job_id"
    t.string "buffet_delivery_reminder_job_id"
    t.string "cutoff_day_before_job_id"
    t.string "cutoff_hour_before_job_id"
    t.string "restaurant_billing_job_id"
    t.string "survey_job_id"
    t.string "fleet_create_task_job_id"
    t.string "fleet_update_task_job_id"
    t.integer "notify_restaurant_job_status", default: 0
    t.integer "cutoff_reached_job_status", default: 0
    t.integer "admin_cutoff_reached_job_status", default: 0
    t.integer "buffet_delivery_reminder_job_status", default: 0
    t.integer "cutoff_day_before_job_status", default: 0
    t.integer "cutoff_hour_before_job_status", default: 0
    t.integer "restaurant_billing_job_status", default: 0
    t.integer "survey_job_status", default: 0
    t.integer "fleet_create_task_job_status", default: 0
    t.integer "fleet_update_task_job_status", default: 0
    t.string "notify_restaurant_job_error"
    t.string "cutoff_reached_job_error"
    t.string "admin_cutoff_reached_job_error"
    t.string "buffet_delivery_reminder_job_error"
    t.string "cutoff_day_before_job_error"
    t.string "cutoff_hour_before_job_error"
    t.string "restaurant_billing_job_error"
    t.string "survey_job_error"
    t.string "fleet_create_task_job_error"
    t.string "fleet_update_task_job_error"
    t.datetime "pickup_at"
    t.string "admin_cutoff_day_before_job_id"
    t.string "admin_cutoff_hour_before_job_id"
    t.integer "admin_cutoff_day_before_job_status", default: 0
    t.integer "admin_cutoff_hour_before_job_status", default: 0
    t.string "admin_cutoff_day_before_job_error"
    t.string "admin_cutoff_hour_before_job_error"
    t.index ["address_id"], name: "runningmenus_address_id_idx"
    t.index ["admin_cutoff_at"], name: "index_runningmenus_on_admin_cutoff_at"
    t.index ["company_id"], name: "runningmenus_company_id_idx"
    t.index ["cutoff_at"], name: "index_runningmenus_on_cutoff_at"
    t.index ["deleted_at", "status", "admin_cutoff_at"], name: "admincutoffreached_reminder_index"
    t.index ["deleted_at", "status", "cutoff_at"], name: "cutoffreached_reminder_index"
    t.index ["deleted_at", "status", "menu_type", "delivery_at", "cutoff_at"], name: "buffet_delivery_reminder_index"
    t.index ["deleted_at"], name: "index_runningmenus_on_deleted_at"
    t.index ["delivery_at"], name: "index_runningmenus_on_delivery_at"
    t.index ["driver_id"], name: "runningmenus_driver_id_idx"
    t.index ["slug"], name: "index_runningmenus_on_slug", unique: true
    t.index ["status"], name: "index_runningmenus_on_status"
    t.index ["user_id"], name: "index_runningmenus_on_user_id"
  end

  create_table "sections", force: :cascade do |t|
    t.integer "parent_id"
    t.bigint "menu_id"
    t.bigint "gsection_id"
    t.string "name", limit: 510
    t.integer "parent_status", default: 0
    t.integer "status", default: 0
    t.text "description"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.integer "draft_id"
    t.integer "section_type", default: 0
    t.index ["deleted_at"], name: "index_sections_on_deleted_at"
    t.index ["gsection_id"], name: "sections_gsection_id_idx"
    t.index ["menu_id"], name: "sections_menu_id_idx"
  end

  create_table "sequences", force: :cascade do |t|
    t.string "name"
    t.integer "restaurants_served", default: 1
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "menu_type", default: 0
  end

  create_table "settings", force: :cascade do |t|
    t.decimal "minimum_amount", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "distance_radius", default: 10
    t.integer "drive_radius", default: 20
    t.boolean "breakfast"
    t.boolean "lunch"
    t.boolean "dinner"
    t.boolean "display_nutritionix"
    t.boolean "display_intercom"
    t.string "realmid"
    t.text "token"
    t.string "refresh_token"
    t.datetime "token_expires_at"
  end

  create_table "share_meetings", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "runningmenu_id"
    t.string "customer_id"
    t.string "last_name", limit: 510
    t.string "first_name", limit: 510
    t.string "email", limit: 510
    t.string "token", limit: 510
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_token"
  end

  create_table "shortened_urls", id: :serial, force: :cascade do |t|
    t.integer "owner_id"
    t.string "owner_type", limit: 20
    t.text "url", null: false
    t.string "unique_key", limit: 10, null: false
    t.string "category"
    t.integer "use_count", default: 0, null: false
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["category"], name: "index_shortened_urls_on_category"
    t.index ["owner_id", "owner_type"], name: "index_shortened_urls_on_owner_id_and_owner_type"
    t.index ["unique_key"], name: "index_shortened_urls_on_unique_key", unique: true
    t.index ["url"], name: "index_shortened_urls_on_url"
  end

  create_table "sms_logs", force: :cascade do |t|
    t.string "from"
    t.string "to"
    t.text "body"
    t.integer "status", default: 0
    t.string "failed_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sms_id"
    t.string "name"
    t.bigint "restaurant_id"
    t.bigint "restaurant_address_id"
    t.index ["restaurant_address_id"], name: "index_sms_logs_on_restaurant_address_id"
    t.index ["restaurant_id"], name: "index_sms_logs_on_restaurant_id"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "tax_rates", force: :cascade do |t|
    t.string "state", limit: 510
    t.string "zip", limit: 510
    t.string "tax_region_name", limit: 510
    t.decimal "state_rate", precision: 8, scale: 4
    t.decimal "estimated_combined_rate", precision: 8, scale: 4
    t.decimal "estimated_county_rate", precision: 8, scale: 4
    t.decimal "estimated_city_rate", precision: 8, scale: 4
    t.decimal "estimated_special_rate", precision: 8, scale: 4
    t.integer "risk_level", default: 0
  end

  create_table "temp_schedules", force: :cascade do |t|
    t.bigint "user_id"
    t.string "cuisines", limit: 510
    t.string "runningmenu_name", limit: 510
    t.integer "runningmenu_type"
    t.integer "address_id"
    t.datetime "delivery_at"
    t.datetime "cutoff_at"
    t.datetime "admin_cutoff_at"
    t.integer "orders_count"
    t.integer "per_meal_budget"
    t.integer "driver_id"
    t.integer "menu_type"
    t.boolean "notify_admin"
    t.boolean "status"
    t.integer "suggested_restaurant"
    t.string "address_ids", limit: 510
    t.string "validation_errors"
    t.index ["user_id"], name: "temp_schedules_user_id_idx"
  end

  create_table "user_requests", force: :cascade do |t|
    t.bigint "company_id"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.boolean "responded", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_user_requests_on_company_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "status", default: 0
    t.integer "parent_status", default: 0
    t.string "customer_id"
    t.bigint "company_id"
    t.bigint "office_admin_id"
    t.bigint "address_id"
    t.string "admin_office_phone", limit: 510
    t.string "email", limit: 510, default: "", null: false
    t.string "encrypted_password", limit: 510, default: "", null: false
    t.string "reset_password_token", limit: 510
    t.datetime "reset_password_sent_at"
    t.string "reset_password_redirect_url", limit: 510
    t.boolean "allow_password_change"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 510
    t.string "last_sign_in_ip", limit: 510
    t.string "confirmation_token", limit: 510
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email", limit: 510
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token", limit: 510
    t.datetime "locked_at"
    t.string "provider", limit: 510
    t.string "uid", limit: 510, default: "", null: false
    t.text "tokens"
    t.string "first_name", limit: 510
    t.string "last_name", limit: 510
    t.string "phone_number", limit: 510
    t.string "desk_phone", limit: 510
    t.boolean "sms_notification"
    t.integer "user_type", default: 0, null: false
    t.integer "profile_completed", default: 0, null: false
    t.integer "invite_accepted", default: 0, null: false
    t.integer "first_time", default: 0, null: false
    t.string "frontend_login_token", limit: 510
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "survey_mail"
    t.boolean "cutoff_day_reminder_mail"
    t.boolean "cutoff_hour_reminder_mail"
    t.string "stripe_user_id", limit: 510
    t.boolean "menu_ready_email"
    t.string "time_zone"
    t.boolean "cutoff_hour_lunch_reminder", default: true
    t.boolean "cutoff_hour_dinner_reminder", default: true
    t.boolean "cutoff_hour_breakfast_reminder", default: true
    t.boolean "cutoff_day_lunch_reminder", default: true
    t.boolean "cutoff_day_dinner_reminder", default: true
    t.boolean "cutoff_day_breakfast_reminder", default: true
    t.boolean "primary_contact", default: false
    t.boolean "allow_admin_to_manage_users", default: true
    t.boolean "disable_grouping_orders", default: false
    t.string "charge_pending_amount_job_id"
    t.boolean "stripe_admin", default: false
    t.string "fax"
    t.boolean "email_summary_check", default: true
    t.boolean "fax_summary_check", default: true
    t.boolean "email_label_check", default: true
    t.boolean "send_text_reminders", default: true
    t.string "reset_password_raw_token"
    t.string "stripe_token"
    t.boolean "admin_cutoff_hour_lunch_reminder", default: true
    t.boolean "admin_cutoff_hour_dinner_reminder", default: true
    t.boolean "admin_cutoff_hour_breakfast_reminder", default: true
    t.boolean "admin_cutoff_day_lunch_reminder", default: true
    t.boolean "admin_cutoff_day_dinner_reminder", default: true
    t.boolean "admin_cutoff_day_breakfast_reminder", default: true
    t.index ["address_id"], name: "users_address_id_idx"
    t.index ["company_id"], name: "users_company_id_idx"
    t.index ["confirmation_token"], name: "users_confirmation_token_key", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["office_admin_id"], name: "users_office_admin_id_idx"
    t.index ["reset_password_token"], name: "users_reset_password_token_key", unique: true
    t.index ["unlock_token"], name: "users_unlock_token_key", unique: true
  end

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string "foreign_key_name", limit: 510, null: false
    t.integer "foreign_key_id"
    t.string "foreign_type", limit: 510
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", limit: 382, null: false
    t.integer "item_id", null: false
    t.string "event", limit: 510, null: false
    t.string "whodunnit", limit: 510
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.integer "transaction_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "users"
  add_foreign_key "addresses_recurring_schedulers", "addresses"
  add_foreign_key "addresses_recurring_schedulers", "recurring_dynamic_sections"
  add_foreign_key "addresses_recurring_schedulers", "recurring_schedulers"
  add_foreign_key "addresses_runningmenus", "addresses"
  add_foreign_key "addresses_runningmenus", "dynamic_sections"
  add_foreign_key "addresses_runningmenus", "runningmenus"
  add_foreign_key "approvers", "billings"
  add_foreign_key "ban_addresses", "addresses"
  add_foreign_key "ban_addresses", "companies"
  add_foreign_key "billings", "companies"
  add_foreign_key "contacts", "addresses"
  add_foreign_key "contacts", "addresses", column: "addresses_id"
  add_foreign_key "cuisines_menus", "cuisines"
  add_foreign_key "cuisines_menus", "runningmenus"
  add_foreign_key "cuisines_recurring_menus", "cuisines"
  add_foreign_key "cuisines_recurring_menus", "recurring_schedulers"
  add_foreign_key "cuisines_requests", "cuisines"
  add_foreign_key "cuisines_requests", "runningmenu_requests"
  add_foreign_key "cuisines_restaurants", "cuisines"
  add_foreign_key "cuisines_restaurants", "restaurants"
  add_foreign_key "cuisines_users", "cuisines"
  add_foreign_key "cuisines_users", "users"
  add_foreign_key "dietaries_fooditems", "dietaries"
  add_foreign_key "dietaries_fooditems", "fooditems"
  add_foreign_key "dietaries_gfooditems", "dietaries"
  add_foreign_key "dietaries_gfooditems", "gfooditems"
  add_foreign_key "dietaries_goptions", "dietaries"
  add_foreign_key "dietaries_goptions", "goptions"
  add_foreign_key "dietaries_options", "dietaries"
  add_foreign_key "dietaries_options", "options"
  add_foreign_key "dietaries_users", "dietaries"
  add_foreign_key "dietaries_users", "users"
  add_foreign_key "dishsize_fooditems", "dishsizes"
  add_foreign_key "dishsize_fooditems", "fooditems"
  add_foreign_key "dynamic_sections", "runningmenus"
  add_foreign_key "favorites", "companies"
  add_foreign_key "favorites", "users"
  add_foreign_key "fieldoptions", "fields"
  add_foreign_key "fields", "companies"
  add_foreign_key "fooditems", "gfooditems"
  add_foreign_key "fooditems", "menus"
  add_foreign_key "fooditems_ingredients", "fooditems"
  add_foreign_key "fooditems_ingredients", "ingredients"
  add_foreign_key "fooditems_optionsets", "fooditems"
  add_foreign_key "fooditems_optionsets", "optionsets"
  add_foreign_key "fooditems_sections", "fooditems"
  add_foreign_key "fooditems_sections", "sections"
  add_foreign_key "gfooditems", "gmenus"
  add_foreign_key "gfooditems_goptionsets", "gfooditems"
  add_foreign_key "gfooditems_goptionsets", "goptionsets"
  add_foreign_key "gfooditems_gsections", "gfooditems"
  add_foreign_key "gfooditems_gsections", "gsections"
  add_foreign_key "gfooditems_ingredients", "gfooditems"
  add_foreign_key "gfooditems_ingredients", "ingredients"
  add_foreign_key "gmenus", "restaurants"
  add_foreign_key "goptions", "goptionsets"
  add_foreign_key "goptions_ingredients", "goptions"
  add_foreign_key "goptions_ingredients", "ingredients"
  add_foreign_key "goptionsets", "gmenus"
  add_foreign_key "gsections", "gmenus"
  add_foreign_key "ingredients_options", "ingredients"
  add_foreign_key "ingredients_options", "options"
  add_foreign_key "logs_attachments", "email_logs"
  add_foreign_key "menus", "addresses"
  add_foreign_key "menus", "gmenus"
  add_foreign_key "options", "goptions"
  add_foreign_key "options", "optionsets"
  add_foreign_key "options_orders", "options"
  add_foreign_key "options_orders", "optionsets_orders"
  add_foreign_key "options_orders", "orders"
  add_foreign_key "optionsets", "goptionsets"
  add_foreign_key "optionsets", "menus"
  add_foreign_key "optionsets_orders", "optionsets"
  add_foreign_key "optionsets_orders", "orders"
  add_foreign_key "order_change_logs", "orders"
  add_foreign_key "orderfields", "companies"
  add_foreign_key "orderfields", "fieldoptions"
  add_foreign_key "orderfields", "fields"
  add_foreign_key "orderfields", "orders"
  add_foreign_key "orders", "addresses"
  add_foreign_key "orders", "companies"
  add_foreign_key "orders", "dishsizes"
  add_foreign_key "orders", "fooditems"
  add_foreign_key "orders", "guests"
  add_foreign_key "orders", "restaurants"
  add_foreign_key "orders", "runningmenus"
  add_foreign_key "orders", "users"
  add_foreign_key "payment_logs", "companies"
  add_foreign_key "ratings", "addresses", column: "restaurant_address_id"
  add_foreign_key "ratings", "orders"
  add_foreign_key "ratings", "restaurants"
  add_foreign_key "ratings", "runningmenus"
  add_foreign_key "recurring_dynamic_sections", "recurring_schedulers"
  add_foreign_key "recurring_schedulers", "addresses"
  add_foreign_key "recurring_schedulers", "companies"
  add_foreign_key "recurring_schedulers", "drivers"
  add_foreign_key "recurring_schedulers", "users"
  add_foreign_key "runningmenu_requests", "addresses"
  add_foreign_key "runningmenu_requests", "companies"
  add_foreign_key "runningmenu_requests", "users"
  add_foreign_key "runningmenufields", "fieldoptions"
  add_foreign_key "runningmenufields", "fields"
  add_foreign_key "runningmenufields", "recurring_schedulers"
  add_foreign_key "runningmenufields", "runningmenus"
  add_foreign_key "runningmenurequestfields", "fieldoptions"
  add_foreign_key "runningmenurequestfields", "fields"
  add_foreign_key "runningmenurequestfields", "runningmenu_requests"
  add_foreign_key "runningmenus", "addresses"
  add_foreign_key "runningmenus", "companies"
  add_foreign_key "runningmenus", "drivers"
  add_foreign_key "sections", "gsections"
  add_foreign_key "sections", "menus"
  add_foreign_key "taggings", "tags"
  add_foreign_key "temp_schedules", "users"
  add_foreign_key "user_requests", "companies"
  add_foreign_key "users", "addresses"
  add_foreign_key "users", "companies"
  add_foreign_key "users", "users", column: "office_admin_id"
end
