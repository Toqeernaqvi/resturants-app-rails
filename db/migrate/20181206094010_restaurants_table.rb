class RestaurantsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :restaurants do |t|
      t.string :name
      t.integer :lunch_order_capacity
      t.integer :dinner_order_capacity
      t.string :notes

      t.datetime  :deleted_at, index: true
      t.timestamps
    end
  end
end
