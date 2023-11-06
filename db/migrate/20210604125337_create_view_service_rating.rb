class CreateViewServiceRating < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_service_rating AS 
      SELECT runningmenus.company_id, companies.name AS company_name, restaurant_addresses.average_rating AS restaurant_rating_avg, (runningmenus.delivery_at AT TIME ZONE 'PST') AS delivery_at, (orders.created_at AT TIME ZONE 'PST') AS created_at, (orders.updated_at AT TIME ZONE 'PST') AS updated_at
      FROM orders
      INNER JOIN runningmenus ON orders.runningmenu_id = runningmenus.id
      INNER JOIN companies ON runningmenus.company_id = companies.id
      INNER JOIN addresses restaurant_addresses ON orders.restaurant_address_id = restaurant_addresses.id
      WHERE orders.status = 0 AND runningmenus.status = 0 AND restaurant_addresses.average_rating > 0"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_service_rating"
  end
end
