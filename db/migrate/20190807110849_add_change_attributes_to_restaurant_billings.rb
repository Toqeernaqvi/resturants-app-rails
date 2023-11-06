class AddChangeAttributesToRestaurantBillings < ActiveRecord::Migration[5.1]
  def self.up
    rename_column :restaurant_billings, :to_be_paid_at, :due_date
    add_column :restaurant_billings, :paid_on, :date
  end
  def self.down
    rename_column :restaurant_billings, :due_date, :to_be_paid_at
    remove_column :restaurant_billings, :paid_on, :date
  end
end
