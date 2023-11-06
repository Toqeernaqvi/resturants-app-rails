class PoplateFooditemRestaurantsInRatings < ActiveRecord::Migration[5.1]
  def change
    Rating.where(ratingable_type: "Fooditem").each do |rating|
      rating.update_columns(restaurant_id: rating.ratingable.menu.address.addressable_id, restaurant_address_id: rating.ratingable.menu.address.id)
    end
  end
end
