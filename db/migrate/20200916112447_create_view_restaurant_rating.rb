class CreateViewRestaurantRating < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_restaurant_rating AS
      SELECT restaurants.id, restaurants.name, AVG(CASE WHEN addresses.average_rating > 0 THEN addresses.average_rating END) AS average_rating
      FROM restaurants
      INNER JOIN addresses ON addresses.addressable_id = restaurants.id AND addresses.addressable_type = 'Restaurant' AND addresses.status = 0
      GROUP BY restaurants.id;"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_restaurant_rating;"
  end
end
