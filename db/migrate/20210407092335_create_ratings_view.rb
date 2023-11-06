class CreateRatingsView < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_ratings AS
    SELECT ratings.id, CONCAT(users.first_name, ' ', users.last_name) AS user, ('Scheduler #' || ratings.runningmenu_id) AS schedule, ('Order #' || ratings.order_id) AS order, companies.name AS company, (CASE ratingable_type WHEN 'Address' THEN 'Restaurant' WHEN 'Runningmenu' THEN 'Services' ELSE ratingable_type END) AS item_type, (CASE ratingable_type WHEN 'Runningmenu' THEN runningmenus.runningmenu_name WHEN 'Fooditem' THEN fooditems.name END) AS item_name, restaurants.name AS restaurant_name, addresses.address_line AS restaurant_location, ratings.rating_value AS rating, ratings.comment, (ratings.created_at AT TIME ZONE 'US/Pacific') AS rated_at
    FROM ratings
    INNER JOIN users ON users.id = ratings.user_id
    INNER JOIN companies ON companies.id = users.company_id
    LEFT JOIN runningmenus ON runningmenus.id = ratings.runningmenu_id
    LEFT JOIN orders ON orders.id = ratings.order_id
    LEFT JOIN addresses ON (addresses.id = ratingable_id AND ratingable_type = 'Address') OR (addresses.id = ratings.restaurant_address_id AND ratingable_type = 'Fooditem')
    LEFT JOIN restaurants ON restaurants.id = addresses.addressable_id AND addressable_type = 'Restaurant'
    LEFT JOIN fooditems ON fooditems.id = ratingable_id AND ratingable_type = 'Fooditem'
    ORDER BY ratings.id DESC;"
  end

  def self.down
    execute "DROP VIEW IF EXISTS view_ratings;"
  end
end
