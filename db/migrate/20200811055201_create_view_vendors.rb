class CreateViewVendors < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_rep_vendors AS
      SELECT DISTINCT view_restaurant_rating.name, companies.name AS company_name, view_restaurant_rating.id AS restaurant_id, cuisines.name AS cuisine, AVG(CASE WHEN view_restaurant_rating.average_rating > 0 THEN view_restaurant_rating.average_rating END ) AS rating, SUM(orders.total_price) AS total_spent, SUM(orders.number_of_meals) AS number_of_meals, companies.id AS company_id, runningmenus.address_id, DATE(runningmenus.delivery_at AT TIME ZONE 'US/PACIFIC') AS dated_on
      FROM runningmenus
      INNER JOIN companies ON companies.id = runningmenus.company_id
      INNER JOIN orders ON orders.runningmenu_id = runningmenus.id AND runningmenus.status = 0 AND orders.status = 0
      INNER JOIN view_restaurant_rating ON view_restaurant_rating.id = orders.restaurant_id
      INNER JOIN cuisines_restaurants ON cuisines_restaurants.restaurant_id = view_restaurant_rating.id
      INNER JOIN cuisines ON cuisines.id = cuisines_restaurants.cuisine_id
      WHERE runningmenus.status = 0 AND orders.status = 0 AND DATE(delivery_at) < CURRENT_DATE
      GROUP BY view_restaurant_rating.id, view_restaurant_rating.name, cuisines.name, companies.id, runningmenus.address_id, dated_on;"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_rep_vendors;"
  end
end