class CuisinesRestaurant < ApplicationRecord
  belongs_to :cuisine
  belongs_to :restaurant
  enum status: [:active, :deleted]
end
