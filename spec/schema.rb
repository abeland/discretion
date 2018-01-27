ActiveRecord::Schema.define do
  self.verbose = false

  # Using the example schema from
  # https://github.com/abeland/discretion/blob/master/README.md

  create_table :staff, force: true do |t|
    t.string :name, null: false
    t.boolean :is_admin, null: false, default: false
    t.timestamps null: false
  end

  create_table :donors, force: true do |t|
    t.string :name, null: false
    t.timestamps null: false
  end

  create_table :donations, force: true do |t|
    t.decimal :amount, precision: 20, scale: 2, null: false
    t.references :donor, null: false
    t.references :staff, null: false
    t.timestamps null: false
  end
end
