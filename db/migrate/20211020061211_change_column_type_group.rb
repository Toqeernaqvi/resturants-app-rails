class ChangeColumnTypeGroup < ActiveRecord::Migration[5.1]
  def self.up
    execute "DROP VIEW IF EXISTS view_orders_detail;"
    change_column :orders, :group, :text
    execute "CREATE OR REPLACE VIEW view_orders_detail AS
      SELECT
        orders.id, orders.user_id, orders.runningmenu_id, orders.invoice_id, runningmenus.address_id, CASE WHEN orders.share_meeting_id IS NOT NULL THEN share_meetings.first_name ELSE users.first_name END, CASE WHEN orders.share_meeting_id IS NOT NULL THEN share_meetings.last_name ELSE users.last_name END, CASE WHEN orders.share_meeting_id IS NOT NULL THEN share_meetings.email ELSE users.email END, (CASE WHEN orders.share_meeting_id IS NOT NULL THEN 'company_user' ELSE (CASE WHEN users.user_type = 1 THEN 'company_admin' WHEN users.user_type = 2 THEN 'company_user' WHEN users.user_type = 7 THEN 'unsubsidized_user' WHEN users.user_type = 6 THEN 'company_manager' END) END) AS user_type, (CASE WHEN orders.status = 1 THEN 'cancelled' ELSE 'active' END) AS status, orders.group, restaurants.name AS restaurant_name, orders.fooditem_id, fooditems.name AS fooditem_name, fooditems.description, fooditems.spicy, fooditems.best_seller, fooditems.price AS fooditem_price, fooditems.gross_price, fooditems.rating_count, fooditems.average_rating, fooditems.skip_markup, dishsizes.title, (dishsizes.serve_count*orders.quantity) AS serve_count, (CASE WHEN menu_type=1 THEN orders.price ELSE orders.total_price END) AS price, ROUND((CASE WHEN orders.user_paid > 0 THEN (CASE WHEN (orders.user_paid+0.30)/(1-0.029) > 0.50 THEN (orders.user_paid+0.30)/(1-0.029) ELSE 0.50 END) ELSE orders.user_paid END), 2) AS user_price, orders.user_paid, orders.company_paid AS company_price, orders.quantity, orders.total_price, (runningmenus.cutoff_at AT TIME ZONE companies.time_zone) AS cutoff_at, (runningmenus.admin_cutoff_at AT TIME ZONE companies.time_zone) AS admin_cutoff_at
      FROM orders
      INNER JOIN runningmenus ON runningmenus.id = orders.runningmenu_id
      INNER JOIN companies ON companies.id = runningmenus.company_id
      INNER JOIN users ON users.id = orders.user_id
      INNER JOIN fooditems ON fooditems.id = orders.fooditem_id
      INNER JOIN restaurants ON restaurants.id = orders.restaurant_id
      LEFT JOIN share_meetings ON share_meetings.id = orders.share_meeting_id
      LEFT JOIN dishsizes ON dishsizes.id = orders.dishsize_id;"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_orders_detail;"
    change_column :orders, :group, :string
    execute "CREATE OR REPLACE VIEW view_orders_detail AS
      SELECT
        orders.id, orders.user_id, orders.runningmenu_id, orders.invoice_id, runningmenus.address_id, CASE WHEN orders.share_meeting_id IS NOT NULL THEN share_meetings.first_name ELSE users.first_name END, CASE WHEN orders.share_meeting_id IS NOT NULL THEN share_meetings.last_name ELSE users.last_name END, CASE WHEN orders.share_meeting_id IS NOT NULL THEN share_meetings.email ELSE users.email END, (CASE WHEN orders.share_meeting_id IS NOT NULL THEN 'company_user' ELSE (CASE WHEN users.user_type = 1 THEN 'company_admin' WHEN users.user_type = 2 THEN 'company_user' WHEN users.user_type = 7 THEN 'unsubsidized_user' WHEN users.user_type = 6 THEN 'company_manager' END) END) AS user_type, (CASE WHEN orders.status = 1 THEN 'cancelled' ELSE 'active' END) AS status, orders.group, restaurants.name AS restaurant_name, orders.fooditem_id, fooditems.name AS fooditem_name, fooditems.description, fooditems.spicy, fooditems.best_seller, fooditems.price AS fooditem_price, fooditems.gross_price, fooditems.rating_count, fooditems.average_rating, fooditems.skip_markup, dishsizes.title, (dishsizes.serve_count*orders.quantity) AS serve_count, (CASE WHEN menu_type=1 THEN orders.price ELSE orders.total_price END) AS price, ROUND((CASE WHEN orders.user_paid > 0 THEN (CASE WHEN (orders.user_paid+0.30)/(1-0.029) > 0.50 THEN (orders.user_paid+0.30)/(1-0.029) ELSE 0.50 END) ELSE orders.user_paid END), 2) AS user_price, orders.user_paid, orders.company_paid AS company_price, orders.quantity, orders.total_price, (runningmenus.cutoff_at AT TIME ZONE companies.time_zone) AS cutoff_at, (runningmenus.admin_cutoff_at AT TIME ZONE companies.time_zone) AS admin_cutoff_at
      FROM orders
      INNER JOIN runningmenus ON runningmenus.id = orders.runningmenu_id
      INNER JOIN companies ON companies.id = runningmenus.company_id
      INNER JOIN users ON users.id = orders.user_id
      INNER JOIN fooditems ON fooditems.id = orders.fooditem_id
      INNER JOIN restaurants ON restaurants.id = orders.restaurant_id
      LEFT JOIN share_meetings ON share_meetings.id = orders.share_meeting_id
      LEFT JOIN dishsizes ON dishsizes.id = orders.dishsize_id;"
  end
end
