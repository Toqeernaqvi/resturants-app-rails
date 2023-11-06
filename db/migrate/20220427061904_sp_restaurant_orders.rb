class SpRestaurantOrders < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION sp_restaurant_orders(p_current_user_id INTEGER, p_start_date TEXT, p_end_date TEXT, p_address_ids TEXT DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
      ROW RECORD;
      SQL TEXT := '';
      currentUser JSON := NULL;
      meeting JSON;
      meetings JSON[];
    BEGIN
      -- Set currentUser
      SELECT row_to_json(u) INTO currentUser
      FROM (SELECT * FROM users WHERE id = p_current_user_id) u;

      IF (currentUser::JSON->>'user_type')::INT = 3 THEN
        SQL = 'SELECT runningmenus.id AS order_id, (runningmenus.pickup_at AT TIME ZONE companies.time_zone) AS pickup, restaurants.name AS restaurant_name, (CASE WHEN addresses_runningmenus.rejected_by_vendor::boolean THEN ''Rejected by vendor'' WHEN addresses_runningmenus.acknowledge_receipt::boolean OR addresses_runningmenus.accept_changes::boolean OR addresses_runningmenus.accept_orders::boolean THEN ''Confirmed'' ELSE ''Unconfirmed'' END) as status, orders.count as order_count, SUM(orders.quantity) AS items_count, orders.restaurant_address_id AS restaurant_id, SUM(orders.new_items_in_last24_hours) as new_items_in_last24_hours,
        (runningmenus.cutoff_at AT TIME ZONE companies.time_zone) AS cutoff_at
        FROM runningmenus 
        INNER JOIN companies ON companies.id = runningmenus.company_id 
        INNER JOIN addresses_runningmenus ON addresses_runningmenus.runningmenu_id = runningmenus.id
        INNER JOIN addresses ON addresses.id = addresses_runningmenus.address_id
        INNER JOIN orders ON orders.runningmenu_id = runningmenus.id AND orders.restaurant_address_id = addresses.id
        INNER JOIN restaurants ON restaurants.id = orders.restaurant_id
        WHERE runningmenus.status = 0 AND orders.status = 0 AND (runningmenus.pickup_at BETWEEN ''' || p_start_date::timestamptz || ''' AND ''' || p_end_date::timestamptz || ''') AND (addresses_runningmenus.address_id IN(' || p_address_ids || '))
        GROUP BY runningmenus.pickup_at, companies.time_zone, addresses.address_name , runningmenus.id, addresses_runningmenus.rejected_by_vendor, addresses_runningmenus.acknowledge_receipt, addresses_runningmenus.accept_changes, addresses_runningmenus.accept_orders, orders.restaurant_address_id, restaurants.name
        ORDER BY runningmenus.pickup_at ASC';
        FOR ROW IN EXECUTE SQL
        LOOP
          SELECT JSON_BUILD_OBJECT('order_id', ROW.order_id, 'pickup', ROW.pickup, 'restaurant_name', ROW.restaurant_name, 'status', ROW.status, 'order_count', ROW.order_count, 'items_count', ROW.items_count, 'new_items_in_last24_hours', ROW.new_items_in_last24_hours ,'cutoff_at', ROW.cutoff_at, 'restaurant_id', ROW.restaurant_id)  INTO meeting;
          meetings := ARRAY_APPEND(meetings, meeting);
        END LOOP;
      END IF;
      RETURN (SELECT TO_JSON(meetings));
    END;
    $$ LANGUAGE plpgsql;"
  end

  def self.down
    execute "DROP FUNCTION IF EXISTS sp_restaurant_orders(p_current_user_id INTEGER, p_start_date TEXT, p_end_date TEXT, p_address_ids TEXT)"
  end
end
