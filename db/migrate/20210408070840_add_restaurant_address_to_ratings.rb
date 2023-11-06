class AddRestaurantAddressToRatings < ActiveRecord::Migration[5.1]
  def change
    add_reference :ratings, :restaurant, foreign_key: true
    add_reference :ratings, :restaurant_address, foreign_key: { to_table: :addresses }
  end
end
