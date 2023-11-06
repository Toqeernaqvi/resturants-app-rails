class CreateViewMostHighRatedAndOrderedMeals < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_most_high_rated_and_ordered_meals AS 
      SELECT runningmenus.company_id, companies.name AS company_name, fooditems.name AS item_name, fooditems.average_rating AS item_rating_avg, orders.quantity, (runningmenus.delivery_at AT TIME ZONE 'PST') AS delivery_at, (orders.created_at AT TIME ZONE 'PST') AS created_at, (orders.updated_at AT TIME ZONE 'PST') AS updated_at
      FROM orders
      INNER JOIN runningmenus ON orders.runningmenu_id = runningmenus.id
      INNER JOIN companies ON runningmenus.company_id = companies.id
      INNER JOIN fooditems ON orders.fooditem_id = fooditems.id
      WHERE orders.status = 0 AND runningmenus.status = 0"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_most_high_rated_and_ordered_meals"
  end
end
