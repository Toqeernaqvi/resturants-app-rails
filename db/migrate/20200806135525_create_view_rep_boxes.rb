class CreateViewRepBoxes < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_rep_boxes AS
      SELECT runningmenus.company_id, runningmenus.address_id, fooditems.average_rating AS average_food_rating, runningmenus.average_rating AS average_service_rating, 0 AS on_time_deliveries, 
        orders.number_of_meals AS meals, orders.restaurant_id AS vendors, view_restaurant_cuisines.cuisines, DATE(runningmenus.delivery_at AT TIME ZONE 'US/PACIFIC') AS dated_on
      FROM runningmenus 
        INNER JOIN orders ON orders.runningmenu_id = runningmenus.id
        INNER JOIN fooditems ON fooditems.id = orders.fooditem_id
        INNER JOIN restaurants ON restaurants.id = orders.restaurant_id
        INNER JOIN view_restaurant_cuisines ON restaurants.id = view_restaurant_cuisines.id
        WHERE runningmenus.status = 0 AND orders.status = 0;"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_rep_boxes"
  end
end
