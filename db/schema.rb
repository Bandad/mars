# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130417165425) do

  create_table "addresses", :force => true do |t|
    t.integer  "company_id"
    t.string   "name"
    t.text     "body"
    t.string   "post_code"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "reference"
  end

  create_table "contacts", :force => true do |t|
    t.string   "name"
    t.integer  "company_id"
    t.string   "job_title"
    t.integer  "address_id"
    t.string   "telephone"
    t.string   "mobile"
    t.string   "fax"
    t.string   "email"
    t.text     "notes"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "contacts", ["address_id"], :name => "index_contacts_on_address_id"
  add_index "contacts", ["company_id"], :name => "index_contacts_on_company_id"

  create_table "projects", :force => true do |t|
    t.string   "code"
    t.string   "name"
    t.integer  "company_id"
    t.date     "start_date"
    t.date     "end_date"
    t.date     "completion_date"
    t.string   "status"
    t.integer  "value"
    t.text     "notes"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "quotation_lines", :force => true do |t|
    t.integer  "quotation_id"
    t.string   "name"
    t.text     "description"
    t.integer  "quantity"
    t.decimal  "unit_price",   :precision => 10, :scale => 2
    t.decimal  "total",        :precision => 10, :scale => 2
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  create_table "quotations", :force => true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.integer  "customer_id"
    t.integer  "supplier_id"
    t.integer  "contact_id"
    t.date     "issue_date"
    t.string   "status"
    t.text     "notes"
    t.integer  "address_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.string   "code"
    t.text     "description"
    t.integer  "delivery_address_id"
  end

  create_table "users", :force => true do |t|
    t.string   "name",                   :default => "", :null => false
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "roles_mask"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
