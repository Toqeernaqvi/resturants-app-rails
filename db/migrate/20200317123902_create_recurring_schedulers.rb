class CreateRecurringSchedulers < ActiveRecord::Migration[5.1]
  def change
    create_table :recurring_schedulers do |t|
    	t.belongs_to :user, foreign_key: true
      t.belongs_to :company, foreign_key: true
      t.belongs_to :address, foreign_key: true
      t.belongs_to :driver, foreign_key: true
      t.integer :runningmenu_type, default: 0
      t.integer :menu_type, default: 0
      t.integer :status, default: 1
      t.integer :parent_status, default: 0
      t.boolean :hide_meeting
      t.text :special_request
      t.string :runningmenu_name
      t.decimal :per_meal_budget
      t.string :deleted_cuisines
      t.boolean :notify_admin
      t.boolean :approve_ban_restaurant
      t.integer :orders_count
      t.integer :per_user_copay
      t.decimal :per_user_copay_amount
      t.datetime :startdate
      t.boolean :monday, default: false
      t.boolean :tuesday, default: false
      t.boolean :wednesday, default: false
      t.boolean :thursday, default: false
      t.boolean :friday, default: false
      t.boolean :saturday, default: false
      t.boolean :sunday, default: false
      t.timestamps
    end
    create_table :addresses_recurring_schedulers do |t|
      t.references :address, index: true, foreign_key: true
      t.references :recurring_scheduler, index: true, foreign_key: true
    end
    create_table :cuisines_recurring_menus do |t|
      t.belongs_to :cuisine, index: true, foreign_key: true
      t.belongs_to :recurring_scheduler, index: true, foreign_key: true
      t.integer :status, default: 0
    end
    add_reference :runningmenufields, :recurring_scheduler, index: true, foreign_key: true
  end
end
