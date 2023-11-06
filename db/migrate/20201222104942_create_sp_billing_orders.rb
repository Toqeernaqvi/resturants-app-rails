class CreateSpBillingOrders < ActiveRecord::Migration[5.1]
  def up
    execute "CREATE OR REPLACE FUNCTION sp_billing_orders(p_billing_id INTEGER, p_time_zone TEXT, p_sort_column TEXT DEFAULT NULL, p_sort_direction TEXT DEFAULT NULL)
    RETURNS TABLE (
      runningmenu_id BIGINT,
      delivery_time DATE,
      food_total NUMERIC(8,2),
      commission NUMERIC(8,2),
      commission_percentage NUMERIC(8,2),
      sales_tax_total NUMERIC(8,2),
      sales_tax_percentage NUMERIC(8,2),
      items BIGINT
    )
    AS $$
    DECLARE
      ROW RECORD;
      SQL TEXT;
    BEGIN
      SQL = 'SELECT runningmenus.id AS runningmenu_id, (delivery_at AT TIME ZONE '''|| p_time_zone ||''') AS delivery_time, SUM(food_price_total) AS food_total, SUM(restaurant_commission) AS commission,
      (CASE WHEN SUM(food_price_total) > 0 THEN ROUND(SUM(restaurant_commission)/SUM(food_price_total), 2) ELSE 0.00 END) AS commission_percentage,
      (CASE WHEN SUM(sales_tax) > 0 THEN ROUND(SUM(sales_tax)/SUM(food_price_total), 2) ELSE 0.00 END) AS sales_tax_percentage,
      SUM(sales_tax) AS sales_tax_total, SUM(quantity) AS items 
      FROM orders 
      INNER JOIN runningmenus ON runningmenus.id = orders.runningmenu_id AND orders.status = 0 AND runningmenus.status = 0 
      WHERE orders.restaurant_billing_id = '|| p_billing_id ||' GROUP BY runningmenus.id';
      IF p_sort_column IS NOT NULL AND p_sort_direction IS NOT NULL THEN
        SQL = SQL || ' ORDER BY '|| p_sort_column ||' '|| p_sort_direction ||' ';
      ELSE
        SQL = SQL || ' ORDER BY delivery_time DESC';
      END IF;
      FOR ROW IN EXECUTE SQL LOOP
        runningmenu_id := row.runningmenu_id::BIGINT;
        delivery_time := row.delivery_time::DATE;
        food_total := row.food_total::NUMERIC(8,2);
        commission := row.commission::NUMERIC(8,2);
        commission_percentage := row.commission_percentage::NUMERIC(8,2);
        sales_tax_total := row.sales_tax_total::NUMERIC(8,2);
        sales_tax_percentage := row.sales_tax_percentage::NUMERIC(8,2);
        items := row.items::BIGINT;
        RETURN NEXT;
      END LOOP;
    END;
    $$ LANGUAGE plpgsql;"
  end

  def down
    execute "DROP FUNCTION IF EXISTS sp_billing_orders(p_billing_id INTEGER, p_time_zone TEXT, p_sort_column TEXT, p_sort_direction TEXT)";
  end
end
