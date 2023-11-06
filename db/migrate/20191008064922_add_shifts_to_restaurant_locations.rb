class AddShiftsToRestaurantLocations < ActiveRecord::Migration[5.1]
  def change
    create_table :restaurant_shifts do |t|
      t.references :address
      t.string :label
      t.datetime :start_time
      t.datetime :end_time
      t.timestamps
    end
  end
end
