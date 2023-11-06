class CreateViewOrders < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_orders AS
      SELECT 
        users.first_name,
        users.last_name,
        CONCAT(users.first_name, ' ', users.last_name) AS user,
        (CASE WHEN users.user_type = 1 THEN 'Company Admin' WHEN users.user_type = 2 THEN 'Company User' WHEN users.user_type = 6 THEN 'Company Manager' WHEN users.user_type = 7 THEN 'Unsubsidized User' END) AS user_role,
        STRING_AGG(DISTINCT dietaries_u.name, ', ') AS user_dietaries,
        companies.id AS company_id,
        companies.name AS company_name,
        companies.user_meal_budget AS company_budget,
        parent_companies.name AS parent_company_name,
        restaurants.name AS restaurant,
        view_restaurant_cuisines.cuisines_str AS restaurant_cuisines,
        restaurant_addresses.latitude AS restaurant_latitude,
        restaurant_addresses.longitude AS restaurant_longitude,
        CONCAT(addresses.street_number, ' ', addresses.street, ', ', addresses.city, ', ', addresses.state, ' ', addresses.zip) AS company_address,
        addresses.latitude AS company_latitude,
        addresses.longitude AS company_longitude,
        orders.site_price AS company_markup,
        fooditems.name AS item_name,
        fooditems.average_rating AS item_rating_avg,
        STRING_AGG(DISTINCT dietaries.name, ', ') AS item_dietaries,
        STRING_AGG(DISTINCT ingredients.name, ', ') AS item_ingredients,
        orders.quantity,
        orders.price,
        orders.company_price,
        orders.user_price,
        orders.total_price,
        orders.user_markup,
        orders.discount AS order_discount,
        restaurant_addresses.buffet_commission,
        restaurant_addresses.buffet_price,
        restaurant_addresses.average_rating AS restaurant_rating_avg,
        restaurant_addresses.discount_percentage AS restaurant_discount_percentage,
        restaurant_addresses.add_contract_commission AS buffet_and_regular_commission,
        CONCAT(restaurant_addresses.street_number, ' ', restaurant_addresses.street, ', ', restaurant_addresses.city, ', ', restaurant_addresses.state, ' ', restaurant_addresses.zip) AS restaurant_address,
        invoices.id AS invoice_id,
        invoices.invoice_number,
        (invoices.created_at AT TIME ZONE 'PST') AS invoice_created_at,
        invoices.total_amount_due,
        invoices.total_discount,
        SUM(line_items.amount) AS delivery_fee,
        SUM(line_items.discount) AS delivery_discount,
        CASE WHEN invoices.status = 0 THEN 'generated' WHEN invoices.status = 1 THEN 'sent' WHEN invoices.status = 2 THEN 'paid' WHEN invoices.status = 3 THEN 'deposited' END AS invoice_status,
        orders.restaurant_payout,
        orders.restaurant_commission,
        restaurant_billings.id AS restaurant_billing_id,
        (restaurant_billings.created_at AT TIME ZONE 'PST') AS restaurant_billing_creation_date,
        (restaurant_billings.due_date AT TIME ZONE 'PST') AS restaurant_billing_due_date,
        CASE WHEN restaurant_billings.payment_status = 0 THEN 'generated' WHEN restaurant_billings.payment_status = 1 THEN 'paid' WHEN restaurant_billings.payment_status = 2 THEN 'final' WHEN restaurant_billings.payment_status = 3 THEN 'due' END AS restaurant_billing_status,
        restaurant_billing_addresses.delayed_payout_days,
        tax_rates.estimated_combined_rate AS tax_rate,
        CASE WHEN orders.status = 0 THEN 'active' ELSE 'cancelled' END AS status,
        (runningmenus.delivery_at AT TIME ZONE 'PST') AS delivery_at,
        (orders.deleted_at AT TIME ZONE 'PST') AS deleted_at,
        (orders.created_at AT TIME ZONE 'PST') AS created_at,
        (orders.updated_at AT TIME ZONE 'PST') AS updated_at
      FROM orders
      INNER JOIN users ON orders.user_id = users.id
      INNER JOIN runningmenus ON orders.runningmenu_id = runningmenus.id
      INNER JOIN companies ON runningmenus.company_id = companies.id
      INNER JOIN addresses ON runningmenus.address_id = addresses.id
      INNER JOIN addresses restaurant_addresses ON orders.restaurant_address_id = restaurant_addresses.id
      INNER JOIN restaurants ON orders.restaurant_id = restaurants.id
      INNER JOIN view_restaurant_cuisines ON view_restaurant_cuisines.id = restaurants.id
      INNER JOIN fooditems ON orders.fooditem_id = fooditems.id
      INNER JOIN tax_rates ON restaurant_addresses.zip = tax_rates.zip
      LEFT JOIN companies parent_companies ON companies.parent_company_id = parent_companies.id
      LEFT JOIN restaurant_billings ON orders.restaurant_billing_id = restaurant_billings.id
      LEFT JOIN addresses restaurant_billing_addresses ON restaurant_billings.address_id = restaurant_billing_addresses.id
      LEFT JOIN invoices ON orders.invoice_id = invoices.id
      LEFT JOIN line_items ON invoices.id = line_items.invoice_id AND line_items.item ILIKE '%delivery%'
      LEFT JOIN dietaries_fooditems ON dietaries_fooditems.fooditem_id = fooditems.id
      LEFT JOIN dietaries ON dietaries.id = dietaries_fooditems.dietary_id
      LEFT JOIN fooditems_ingredients ON fooditems_ingredients.fooditem_id = fooditems.id
      LEFT JOIN ingredients ON ingredients.id = fooditems_ingredients.ingredient_id
      LEFT JOIN dietaries_users ON dietaries_users.user_id = users.id
      LEFT JOIN dietaries dietaries_u ON dietaries_u.id = dietaries_users.dietary_id
      GROUP BY users.id, companies.id, parent_companies.id, restaurants.id, addresses.id, orders.id, fooditems.id, restaurant_addresses.id, tax_rates.id, runningmenus.id, invoices.id, restaurant_billings.id, restaurant_billing_addresses.id, cuisines_str
      ORDER BY orders.created_at desc;"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_orders"
  end
end
