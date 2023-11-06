class OrdersNotBilledProcedure < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE VIEW ORDER_NOT_BILLED_VIEW AS
      SELECT orders.id, (CASE WHEN (share_meetings.first_name != '' OR share_meetings.last_name != '') THEN CONCAT(share_meetings.first_name, ' ' , share_meetings.last_name) ELSE CONCAT(users.first_name, ' ' , users.last_name) END) AS user_name, companies.name, restaurants.name AS restaurant_name, addresses.address_line AS company_location, fooditems.name AS fooditem_name, runningmenus.id AS runningmenu_id, orders.price, orders.company_price, orders.user_price, orders.site_price, orders.quantity, orders.total_price, orders.discount, (orders.total_price - orders.discount) AS discounted_total_price, 
      runningmenus.delivery_instructions, orders.invoice_id AS invoice_id,  orders.created_at, runningmenus.delivery_at, (CASE WHEN orders.status = 0 THEN 'active' ELSE 'cancelled' END) AS status FROM orders
      INNER JOIN runningmenus ON runningmenus.id = orders.runningmenu_id
      INNER JOIN companies ON companies.id = runningmenus.company_id
      INNER JOIN restaurants ON restaurants.id = orders.restaurant_id
      INNER JOIN addresses ON runningmenus.address_id = addresses.id
      INNER JOIN fooditems ON orders.fooditem_id = fooditems.id
      LEFT JOIN share_meetings ON orders.share_meeting_id = share_meetings.id
      INNER JOIN users ON orders.user_id = users.id
      WHERE orders.status = '#{Order.statuses[:active]}'
      AND runningmenus.status = 0
      AND orders.restaurant_billing_id IS NULL
      ORDER BY runningmenus.delivery_at DESC;"
  end
  def self.down
    execute "DROP VIEW IF EXISTS ORDER_NOT_BILLED_VIEW"
  end
end
