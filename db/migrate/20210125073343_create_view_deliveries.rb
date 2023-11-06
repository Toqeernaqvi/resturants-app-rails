class CreateViewDeliveries < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_deliveries AS (
      SELECT id, slug, runningmenu_name, delivery_at, cutoff_at, admin_cutoff_at, company_id, company_name, formatted_address, STRING_AGG(restaurant_name || '<br />' || quantity || '<br />' || logo, '<br />') AS restaurant, SUM(quantity) AS total_quantity
      FROM
      (
      SELECT runningmenus.id, runningmenus.slug, runningmenus.runningmenu_name, runningmenus.delivery_at, runningmenus.cutoff_at, runningmenus.admin_cutoff_at, companies.id AS company_id, 
      companies.name AS company_name, (CASE WHEN company_addresses.address_name IS NULL OR company_addresses.address_name = '' THEN CONCAT_WS(': ', companies.name, CONCAT_WS(', ', CONCAT_WS(' ', NULLIF(company_addresses.street_number, ''), company_addresses.street), NULLIF(company_addresses.suite_no, ''), NULLIF(company_addresses.city, ''))) ELSE CONCAT_WS(': ', company_addresses.address_name, CONCAT_WS(', ', CONCAT_WS(' ', NULLIF(company_addresses.street_number, ''),company_addresses.street), NULLIF(company_addresses.suite_no, ''), NULLIF(company_addresses.city, ''))) END) AS formatted_address, restaurants.name AS restaurant_name, STRING_AGG(DISTINCT CASE WHEN restaurant_addresses.logo IS NULL THEN '' ELSE '/uploads/address/logo/' || restaurant_addresses.id || '/medium_' || restaurant_addresses.logo END, '') AS logo, COALESCE(SUM(orders.quantity), 0)::INT AS quantity
      FROM runningmenus
        INNER JOIN companies ON runningmenus.company_id = companies.id
        INNER JOIN addresses company_addresses ON runningmenus.address_id = company_addresses.id AND company_addresses.status = 0
        INNER JOIN addresses_runningmenus ON addresses_runningmenus.runningmenu_id = runningmenus.id
        INNER JOIN addresses restaurant_addresses ON restaurant_addresses.id = addresses_runningmenus.address_id AND restaurant_addresses.status = 0 
        INNER JOIN restaurants ON restaurants.id = restaurant_addresses.addressable_id AND restaurant_addresses.addressable_type = 'Restaurant' AND restaurants.status = 0
        LEFT JOIN orders ON orders.runningmenu_id = runningmenus.id AND orders.restaurant_address_id = restaurant_addresses.id AND orders.status = 0
        WHERE runningmenus.status = 0
      GROUP BY restaurants.id, runningmenus.id, companies.id, company_addresses.id
      ) AS tbl
      GROUP BY id, slug, runningmenu_name, delivery_at, cutoff_at, admin_cutoff_at, company_id, company_name, formatted_address
    );"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_deliveries;"
  end
end
