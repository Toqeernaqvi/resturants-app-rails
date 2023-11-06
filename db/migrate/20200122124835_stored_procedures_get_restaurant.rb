class StoredProceduresGetRestaurant < ActiveRecord::Migration[5.1]
  def up
    execute "DROP FUNCTION IF EXISTS get_restaurant(scheduler_id INT, show_order_diff BOOLEAN);
      CREATE OR REPLACE FUNCTION get_restaurant(scheduler_id INT, show_order_diff BOOLEAN)
      RETURNS TABLE (
      	restaurant_id BIGINT,
      	restaurant_name VARCHAR,
      	company_location_id BIGINT,
      	company_name VARCHAR,
      	company_location TEXT,
      	addresses_short_code VARCHAR,
      	address_id INTEGER
      )
      AS $$
      BEGIN
      	RETURN QUERY EXECUTE 'SELECT orders.restaurant_id AS restaurant_id, restaurants.name AS restaurant_name, runningmenus.address_id AS company_location_id,
      	companies.name AS company_name, CONCAT(companies.name, '':'' , addresses.address_line) AS company_location,
      	addresses.short_code AS addresses_short_code, orders.restaurant_address_id AS address_id
      	  FROM orders
      	  INNER JOIN runningmenus ON orders.runningmenu_id = runningmenus.id
      	  INNER JOIN companies ON runningmenus.company_id = companies.id
      	  INNER JOIN addresses ON runningmenus.address_id = addresses.id
      	  INNER JOIN restaurants ON orders.restaurant_id = restaurants.id
          WHERE 1=1 AND'||
          CASE WHEN show_order_diff = true
          THEN ' orders.latest_version_id IS NOT NULL AND restaurants.status =  0 AND runningmenu_id =' || scheduler_id
          ELSE  ' orders.status = 0  AND restaurants.status = 0 AND runningmenu_id ='|| scheduler_id
      	  END
      	  || ' GROUP BY restaurant_id, runningmenus.address_id, runningmenus.company_id, restaurants.name, companies.name, addresses.address_line, addresses.short_code, orders.restaurant_address_id
          ORDER BY restaurant_name ASC';
      END;
      $$ LANGUAGE plpgsql;"
  end

  def down
    execute "DROP FUNCTION IF EXISTS get_restaurant(scheduler_id INT, show_order_diff BOOLEAN);";
  end
end
