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

ActiveRecord::Schema[7.1].define(version: 2026_03_28_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customers_on_email", unique: true
  end

  create_table "rails_simple_event_sourcing_events", force: :cascade do |t|
    t.string "eventable_type"
    t.bigint "eventable_id"
    t.string "type", null: false
    t.string "aggregate_id"
    t.bigint "version"
    t.jsonb "payload"
    t.jsonb "metadata"
    t.integer "schema_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type"], name: "index_rails_simple_event_sourcing_events_on_type"
    t.index ["eventable_type", "aggregate_id", "version"], name: "index_events_on_eventable_type_and_aggregate_id_and_version", unique: true
    t.index ["eventable_type", "eventable_id"], name: "index_rails_simple_event_sourcing_events_on_eventable"
    t.index ["metadata"], name: "index_rails_simple_event_sourcing_events_on_metadata", using: :gin
    t.index ["payload"], name: "index_rails_simple_event_sourcing_events_on_payload", using: :gin
  end

  create_table "rails_simple_event_sourcing_snapshots", force: :cascade do |t|
    t.string "aggregate_type", null: false
    t.string "aggregate_id", null: false
    t.jsonb "state", default: {}, null: false
    t.integer "version", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aggregate_type", "aggregate_id"], name: "index_snapshots_on_aggregate_type_and_aggregate_id", unique: true
  end

end
