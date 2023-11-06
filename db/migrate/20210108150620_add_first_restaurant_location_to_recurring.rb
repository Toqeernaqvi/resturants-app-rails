class AddFirstRestaurantLocationToRecurring < ActiveRecord::Migration[5.1]
  def change
    add_column :recurring_schedulers, :first_restaurant, :integer
  end
end
