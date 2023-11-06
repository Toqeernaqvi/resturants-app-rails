class AddTempScheduleTable < ActiveRecord::Migration[5.1]
  def change
    create_table :temp_schedules do |t|
      t.references  :user, index: true, foreign_key: true
      t.string :cuisines
      t.string :runningmenu_name
      t.integer :runningmenu_type
      t.integer :address_id
      t.datetime :delivery_at
      t.datetime :cutoff_at
      t.datetime :admin_cutoff_at
      t.integer :orders_count
      t.integer :per_meal_budget
      t.integer :driver_id
      t.integer :menu_type
      t.boolean :notify_admin
      t.boolean :status
      t.integer :suggested_restaurant
    end
  end
end
