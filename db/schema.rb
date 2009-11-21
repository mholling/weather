# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091121003356) do

  create_table "chartings", :force => true do |t|
    t.integer  "chart_id"
    t.integer  "instrument_id"
    t.text     "config"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "charts", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.text     "config"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "components", :force => true do |t|
    t.integer  "device_id"
    t.integer  "instrument_id"
    t.text     "config"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "devices", :force => true do |t|
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "instruments", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.text     "config"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "observations", :force => true do |t|
    t.integer  "instrument_id"
    t.float    "value"
    t.datetime "time"
    t.date     "meteorological_date"
  end

  create_table "scales", :force => true do |t|
    t.string   "name"
    t.text     "config"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.integer  "interval"
    t.string   "units"
  end

  create_table "scalings", :force => true do |t|
    t.integer  "scalable_id"
    t.integer  "scale_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "scalable_type"
  end

  create_table "statistics", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.text     "config"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "variables", :force => true do |t|
    t.integer  "statistic_id"
    t.integer  "instrument_id"
    t.text     "config"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
