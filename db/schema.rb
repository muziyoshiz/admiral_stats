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

ActiveRecord::Schema.define(version: 20170429115714) do

  create_table "admiral_publications", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "admiral_id",                                        null: false
    t.string   "name",                   limit: 32,                 null: false
    t.string   "url_name",               limit: 32,                 null: false
    t.boolean  "opens_twitter_nickname",            default: false, null: false
    t.boolean  "opens_ship_list",                   default: false, null: false
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.index ["admiral_id"], name: "index_admiral_publications_on_admiral_id", unique: true, using: :btree
    t.index ["url_name"], name: "index_admiral_publications_on_url_name", unique: true, using: :btree
  end

  create_table "admiral_statuses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "admiral_id",                null: false
    t.integer  "fuel",                      null: false
    t.integer  "ammo",                      null: false
    t.integer  "steel",                     null: false
    t.integer  "bauxite",                   null: false
    t.integer  "bucket",                    null: false
    t.integer  "level",                     null: false
    t.integer  "room_item_coin",            null: false
    t.string   "result_point",   limit: 32
    t.string   "rank",           limit: 32
    t.integer  "title_id"
    t.integer  "strategy_point"
    t.integer  "kou_medal"
    t.datetime "exported_at",               null: false
    t.index ["admiral_id", "exported_at"], name: "index_admiral_statuses_on_admiral_id_and_exported_at", unique: true, using: :btree
  end

  create_table "admiral_tokens", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "admiral_id", null: false
    t.string   "token",      null: false
    t.datetime "issued_at",  null: false
  end

  create_table "admirals", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "twitter_uid",      limit: 32, null: false
    t.string   "twitter_nickname", limit: 32, null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["twitter_uid"], name: "index_admirals_on_twitter_uid", unique: true, using: :btree
  end

  create_table "api_request_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "admiral_id",               null: false
    t.string   "request_method", limit: 7, null: false
    t.string   "request_uri",              null: false
    t.string   "user_agent"
    t.integer  "status_code",              null: false
    t.string   "response"
    t.datetime "created_at",               null: false
  end

  create_table "event_masters", primary_key: "event_no", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "event_name", limit: 32, null: false
    t.datetime "started_at",            null: false
    t.datetime "ended_at",              null: false
  end

  create_table "event_progress_statuses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "admiral_id",                            null: false
    t.integer  "event_no",                              null: false
    t.string   "level",                       limit: 8, null: false
    t.boolean  "opened",                                null: false
    t.integer  "current_loop_counts",                   null: false
    t.integer  "cleared_loop_counts",                   null: false
    t.integer  "cleared_stage_no",                      null: false
    t.integer  "current_military_gauge_left",           null: false
    t.datetime "exported_at",                           null: false
    t.index ["admiral_id", "event_no", "level", "exported_at"], name: "index_event_progress_statuses", unique: true, using: :btree
  end

  create_table "event_ship_card_ownerships", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "event_no",           null: false
    t.integer  "book_no",            null: false
    t.integer  "card_index",         null: false
    t.integer  "no_of_owners",       null: false
    t.integer  "no_of_active_users", null: false
    t.datetime "reported_at",        null: false
    t.index ["event_no", "book_no", "card_index", "reported_at"], name: "index_event_ship_card_ownerships", unique: true, using: :btree
  end

  create_table "event_stage_masters", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "event_no",                          null: false
    t.string  "level",                  limit: 32, null: false
    t.integer "stage_no",                          null: false
    t.string  "stage_mission_name",     limit: 32, null: false
    t.integer "ene_military_gauge_val",            null: false
    t.index ["event_no", "level", "stage_no"], name: "index_event_stage_masters", unique: true, using: :btree
  end

  create_table "ship_card_ownerships", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "book_no",            null: false
    t.integer  "card_index",         null: false
    t.integer  "no_of_owners",       null: false
    t.integer  "no_of_active_users", null: false
    t.datetime "reported_at",        null: false
    t.index ["book_no", "card_index", "reported_at"], name: "index_ship_card_ownerships", unique: true, using: :btree
  end

  create_table "ship_card_timestamps", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "admiral_id",  null: false
    t.datetime "exported_at", null: false
    t.index ["admiral_id", "exported_at"], name: "index_ship_card_timestamps_on_admiral_id_and_exported_at", unique: true, using: :btree
  end

  create_table "ship_cards", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "admiral_id",        null: false
    t.integer  "book_no",           null: false
    t.integer  "card_index",        null: false
    t.datetime "first_exported_at", null: false
    t.index ["admiral_id", "book_no", "card_index"], name: "index_ship_cards_on_admiral_id_and_book_no_and_card_index", unique: true, using: :btree
  end

  create_table "ship_masters", primary_key: "book_no", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "ship_class",       limit: 32,             null: false
    t.integer  "ship_class_index",                        null: false
    t.string   "ship_type",        limit: 32,             null: false
    t.string   "ship_name",        limit: 32,             null: false
    t.integer  "variation_num",                           null: false
    t.integer  "remodel_level",               default: 0, null: false
    t.datetime "implemented_at"
  end

  create_table "ship_slot_statuses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "ship_status_id",             null: false
    t.integer "slot_index",                 null: false
    t.string  "slot_equip_name", limit: 32, null: false
    t.integer "slot_amount",                null: false
    t.integer "slot_disp",                  null: false
    t.index ["ship_status_id", "slot_index"], name: "index_ship_slot_statuses", unique: true, using: :btree
  end

  create_table "ship_statuses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "admiral_id",          null: false
    t.integer  "book_no",             null: false
    t.integer  "remodel_level",       null: false
    t.integer  "level",               null: false
    t.integer  "star_num"
    t.integer  "exp_percent"
    t.integer  "blueprint_total_num"
    t.datetime "exported_at",         null: false
    t.index ["admiral_id", "book_no", "remodel_level", "exported_at"], name: "index_ship_statuses", unique: true, using: :btree
  end

  create_table "updated_ship_masters", primary_key: "book_no", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "ship_class",       limit: 32,             null: false
    t.integer  "ship_class_index",                        null: false
    t.string   "ship_type",        limit: 32,             null: false
    t.string   "ship_name",        limit: 32,             null: false
    t.integer  "variation_num",                           null: false
    t.integer  "remodel_level",               default: 0, null: false
    t.datetime "implemented_at",                          null: false
  end

end
