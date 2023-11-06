class CreateRestaurantsBillings < ActiveRecord::Migration[5.1]
  def change
    create_table :restaurant_billings do |t|
      t.references :restaurant
      t.references :address
      t.integer :payment_status, default: 0
      t.integer :status, default: 0
      t.timestamps
    end
  end
end
