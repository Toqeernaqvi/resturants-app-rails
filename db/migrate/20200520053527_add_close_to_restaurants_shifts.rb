class AddCloseToRestaurantsShifts < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurant_shifts, :closed, :boolean, default: false
  end
end
