class StoredProceduresGetInvoiceOrders < ActiveRecord::Migration[5.1]
  def up
    execute "CREATE OR REPLACE FUNCTION get_orders(back_time TEXT, current_time_ TEXT, p_company_id INTEGER DEFAULT NULL)
    RETURNS TABLE (
    	company_id BIGINT,
      delivery_type TEXT,
      restaurant_id BIGINT,
      restaurant_address_id INT,
    	bm TEXT,
    	gl TEXT,
    	ie TEXT,
    	order_id BIGINT,
    	runningmenu_id BIGINT,
    	address_id BIGINT,
    	ordered_at timestamptz
    )
    AS $$
    DECLARE
    	ROW RECORD;
    	SQL TEXT;
    BEGIN
      SQL = 'SELECT tbl.company_id, tbl.delivery_type, tbl.restaurant_id, tbl.restaurant_address_id, MAX(CASE WHEN tbl.field_name =''BM Number'' THEN tbl.field_value END) bm,
            MAX(CASE WHEN tbl.field_name =''GL String'' THEN tbl.field_value END) gl, MAX(CASE WHEN tbl.field_name =''Invoice Email'' THEN tbl.field_value END) ie,
            tbl.order_id, tbl.runningmenu_id, tbl.address_id, tbl.ordered_at
            FROM
              (
                SELECT orders.id as order_id, orders.runningmenu_id as runningmenu_id, (CASE runningmenus.delivery_type WHEN 1 THEN ''delivery'' ELSE ''pickup'' END) AS delivery_type, orders.restaurant_id, orders.restaurant_address_id, runningmenus.address_id as address_id,
                  runningmenus.delivery_at as ordered_at, runningmenus.company_id as company_id, fields.name as field_name,
                  (CASE WHEN fields.field_type = 0 THEN fieldoptions.name ELSE runningmenufields.value END) AS field_value
                FROM orders
                  LEFT JOIN runningmenufields on runningmenufields.runningmenu_id = orders.runningmenu_id
                  LEFT JOIN fields on fields.id = runningmenufields.field_id AND (fields.name=''BM Number'' OR fields.name=''GL String'' OR fields.name=''Invoice Email'' ) AND fields.status = 0
                  LEFT JOIN fieldoptions ON fieldoptions.id = runningmenufields.fieldoption_id
                  INNER JOIN runningmenus on runningmenus.id = orders.runningmenu_id
                  INNER JOIN billings on billings.company_id = runningmenus.company_id
                WHERE orders.invoice_id IS NULL AND orders.status =  0
                AND (runningmenus.delivery_at BETWEEN ''' || back_time::timestamptz || ''' AND ''' || current_time_ ::timestamptz || ''' )';
      IF p_company_id IS NOT NULL THEN
        SQL = SQL || ' AND billings.disable_auto_invoice = true AND billings.company_id = ' || p_company_id;
      ELSE
        SQL = SQL || ' AND billings.disable_auto_invoice = false AND runningmenus.delivery_type = 0';
      END IF;
      SQL = SQL || ' GROUP BY orders.id, orders.runningmenu_id, runningmenus.delivery_type, runningmenus.address_id, runningmenus.delivery_at, runningmenus.company_id, field_name, field_value) AS tbl 
      GROUP BY tbl.company_id, tbl.delivery_type, tbl.restaurant_id, tbl.restaurant_address_id, tbl.order_id, tbl.runningmenu_id, tbl.address_id, tbl.ordered_at';
      FOR ROW IN EXECUTE SQL LOOP
        company_id := row.company_id::BIGINT;
        delivery_type := row.delivery_type::TEXT;
        restaurant_id := row.restaurant_id::BIGINT;
        restaurant_address_id := row.restaurant_address_id::INT;
        bm := row.bm::TEXT;
        gl := row.gl::TEXT;
        ie := row.ie::TEXT;
        order_id := row.order_id::BIGINT;
        runningmenu_id := row.runningmenu_id::BIGINT;
        address_id := row.address_id::BIGINT;
        ordered_at := row.ordered_at::timestamptz;
        RETURN NEXT;
      END LOOP;
    END;
    $$ LANGUAGE plpgsql;"
  end

  def down
    execute "DROP FUNCTION IF EXISTS get_orders(back_time TEXT, current_time_ TEXT, p_company_id INTEGER)";
  end
end
