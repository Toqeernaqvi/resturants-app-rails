class StoredProcedureGetOrderAtAdminCutoff < ActiveRecord::Migration[5.1]
  def up
    execute "DROP FUNCTION IF EXISTS order_at_admin_cutoff(scheduler_id INT);
    DROP FUNCTION IF EXISTS order_at_admin_cutoff(scheduler_id INT);
    CREATE OR REPLACE FUNCTION order_at_admin_cutoff(scheduler_id INT)
    RETURNS TABLE (
    	user_name TEXT,
    	user_email VARCHAR,
    	fooditem_name VARCHAR,
    	options TEXT,
    	event VARCHAR,
    	event_date timestamptz
    )
    AS $$
    BEGIN
    RETURN QUERY SELECT CONCAT(users.first_name, ' ' , users.last_name) AS user_name,
                users.email AS user_email, fooditems.name AS fooditem_name,
                (
                  SELECT STRING_AGG(options.description, ', ')
                  FROM options
                  INNER JOIN options_orders ON options.id=options_orders.option_id
                  INNER JOIN optionsets_orders ON options_orders.optionsets_order_id=optionsets_orders.id
                  INNER JOIN orders AS o ON optionsets_orders.order_id=o.id
                  WHERE o.id = orders.id
                ) AS options,
                (CASE WHEN (orders.status = 1 AND versions.event = 'update') THEN 'delete' ELSE versions.event END) AS event,
    				versions.created_at AS event_date
              FROM orders
                INNER JOIN runningmenus ON runningmenus.id = orders.runningmenu_id
                INNER JOIN users ON orders.user_id = users.id
                INNER JOIN fooditems ON orders.fooditem_id = fooditems.id
                INNER JOIN versions ON orders.latest_version_id = versions.id
                WHERE orders.latest_version_id IS NOT NULL AND runningmenu_id = scheduler_id AND versions.created_at BETWEEN runningmenus.cutoff_at AND runningmenus.admin_cutoff_at;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

  def down
    execute "DROP FUNCTION IF EXISTS order_at_admin_cutoff(scheduler_id INT);"
  end
end
