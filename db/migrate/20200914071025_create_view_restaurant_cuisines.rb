class CreateViewRestaurantCuisines < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_restaurant_cuisines AS
      SELECT restaurants.id, restaurants.name, STRING_AGG(cuisines.name, ', ') AS cuisines_str, ARRAY_AGG(cuisines.name) AS cuisines, COUNT(cuisines.id) AS total
      FROM restaurants
      LEFT join cuisines_restaurants on cuisines_restaurants.restaurant_id = restaurants.id
      LEFT join cuisines on cuisines.id = cuisines_restaurants.cuisine_id 
      WHERE restaurants.status = 0
      GROUP BY restaurants.id;"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_restaurant_cuisines"
  end
end
