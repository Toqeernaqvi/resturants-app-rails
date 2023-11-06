class CreateViewMostUsedCuisines < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_most_used_cuisines AS 
      SELECT restaurants.name AS restaurant, runningmenus.company_id, companies.name AS company_name, view_restaurant_cuisines.cuisines_str AS restaurant_cuisines, orders.quantity, (runningmenus.delivery_at AT TIME ZONE 'PST') AS delivery_at, (orders.created_at AT TIME ZONE 'PST') AS created_at, (orders.updated_at AT TIME ZONE 'PST') AS updated_at
      FROM orders
      INNER JOIN runningmenus ON orders.runningmenu_id = runningmenus.id
      INNER JOIN companies ON runningmenus.company_id = companies.id
      INNER JOIN restaurants ON orders.restaurant_id = restaurants.id
      INNER JOIN view_restaurant_cuisines ON view_restaurant_cuisines.id = restaurants.id
      WHERE orders.status = 0 AND runningmenus.status = 0"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_most_used_cuisines"
  end
end
