class CreateSpOrdersDetail < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION sp_orders_detail(p_company_id INTEGER, p_address_id INTEGER, p_runningmenu_id INTEGER, p_backend_host TEXT, p_order_by TEXT, p_order_type TEXT, p_current_user_id INTEGER DEFAULT NULL, p_share_meeting_id INTEGER DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
          SQL TEXT := '';
          ROW RECORD;
          currentUser JSON := NULL;
          company JSON;
          runningmenu JSON;
          runningmenu_fields JSON;
          address JSON;
          user_obj JSON;
          order_obj JSON;
          fooditem JSON;
          orders JSON[];
          total_order_price DECIMAL := 0.00;
          total_user_paid DECIMAL := 0.00;
          total_order_quantity INTEGER := 0;
          order_price_total DECIMAL := 0.00;
          total_quantity INTEGER := 0;
          cancelled_total_quantity INTEGER := 0;
          restaurants TEXT[];
          restaurants_names TEXT;
          p_invoice_id INTEGER := NULL;
          delivery_fee DECIMAL := 0.00;
          invoice_download_link TEXT := NULL;
          nutritions JSON;
        BEGIN
          IF p_current_user_id IS NOT NULL THEN
            SELECT row_to_json(u) INTO currentUser
            FROM (SELECT * FROM users WHERE id = p_current_user_id) u;
          END IF;

          SELECT row_to_json(comp) INTO company
          FROM (SELECT * FROM companies WHERE companies.id = p_company_id) comp;

          IF p_share_meeting_id IS NOT NULL THEN
            SQL = 'SELECT *, CONCAT(first_name, '' '', last_name) AS full_name FROM view_orders_detail WHERE share_meeting_id = '|| p_share_meeting_id ||'';
          ELSE
            SQL = 'SELECT *, CONCAT(first_name, '' '', last_name) AS full_name FROM (SELECT NULL AS id, NULL AS guest_id, id AS user_id, NULL AS runningmenu_id,
             NULL AS share_meeting_id, NULL AS invoice_id, users.address_id, first_name, last_name, email,
            (CASE WHEN user_type=1 THEN ''company_admin'' WHEN user_type=2 THEN ''company_user'' WHEN user_type=6 THEN ''company_manager'' WHEN user_type=7 THEN ''unsubsidized_user'' END) AS user_type, ''unordered'' AS status, NULL AS group, NULL AS restaurant_name,
            NULL AS fooditem_id, NULL AS fooditem_name, NULL AS description, NULL AS spicy, NULL AS best_seller, NULL AS fooditem_price, NULL AS gross_price,
            NULL AS rating_count, NULL AS average_rating, NULL AS skip_markup, NULL AS title, NULL AS serve_count, NULL AS price, NULL AS user_price, NULL AS user_paid, NULL AS company_price, NULL AS quantity,
            NULL AS total_price, NULL AS cutoff_at, NULL AS admin_cutoff_at, NULL AS remarks, NULL AS selected_options
            FROM users
            WHERE users.status = 0 AND company_id = '|| p_company_id ||' AND address_id = '|| p_address_id ||' AND id NOT IN(SELECT user_id FROM view_orders_detail WHERE runningmenu_id = '|| p_runningmenu_id ||')';
            SQL = SQL || ' UNION SELECT * FROM view_orders_detail WHERE runningmenu_id = '|| p_runningmenu_id ||' AND address_id = '|| p_address_id ||'';
          END IF;          
          IF currentUser IS NOT NULL AND ((currentUser::json->>'user_type')::int = 2 OR (currentUser::json->>'user_type')::int = 6 OR (currentUser::json->>'user_type')::int = 7) THEN
            SQL = SQL || ' AND user_id = '|| p_current_user_id ||' ';
          END IF;
          IF p_share_meeting_id IS NULL THEN
            SQL = SQL || ' ) AS tbl';
          END IF;
          IF p_order_by = 'user' THEN
            SQL = SQL || ' ORDER BY first_name '|| p_order_type || ', last_name '|| p_order_type || ' ';
          END IF;
          IF p_order_by = 'item' THEN
            SQL = SQL || ' ORDER BY fooditem_name '|| p_order_type || ' ';
          END IF;
          IF p_order_by = 'status' THEN
            SQL = SQL || ' ORDER BY status '|| p_order_type || ' ';
          END IF;
          FOR ROW IN EXECUTE SQL
          LOOP
            SELECT JSON_BUILD_OBJECT('id', ROW.user_id, 'name', ROW.full_name, 'email', ROW.email, 'is_admin', CASE WHEN ROW.user_type = 'company_admin' THEN TRUE ELSE FALSE END, 'user_type', ROW.user_type) INTO user_obj;
            IF ROW.fooditem_id IS NOT NULL THEN
              SELECT COALESCE(JSON_AGG(nutrition), '[]') INTO nutritions
              FROM (SELECT nutritional_facts.id AS id, nutritions.id AS nutrition_id, nutritions.name, nutritional_facts.value FROM nutritions 
                INNER JOIN nutritional_facts ON nutritions.id = nutritional_facts.nutrition_id 
                WHERE nutritional_facts.factable_id = ROW.fooditem_id AND nutritional_facts.factable_type = 'Fooditem' AND (nutritions.parent_id IS NULL) AND (name='Calories') ORDER BY nutritional_facts.id ASC LIMIT 1
              ) nutrition;
            END IF;  
            SELECT JSON_BUILD_OBJECT('id', ROW.fooditem_id, 'name', ROW.fooditem_name, 'description', ROW.description, 'best_seller', ROW.best_seller, 'price', ROW.fooditem_price, 'gross_price', ROW.gross_price, 'total_price', ROW.total_price, 'serve_count', ROW.serve_count, 'dishsize', ROW.title, 'rating_count', ROW.rating_count, 'average_rating', ROW.average_rating, 'skip_markup', ROW.skip_markup, 'nutritions', nutritions) INTO fooditem;
            SELECT JSON_BUILD_OBJECT('id', ROW.id, 'guest_id', ROW.guest_id, 'share_meeting_id', ROW.share_meeting_id, 'status', ROW.status, 'group', ROW.group, 'restaurant_name', ROW.restaurant_name, 'cutoff_at', ROW.cutoff_at, 'admin_cutoff_at', ROW.admin_cutoff_at, 'quantity', ROW.quantity, 'price', ROW.price, 'user_price', ROW.user_price, 'company_price', ROW.company_price, 'user', user_obj, 'fooditem', CASE WHEN ROW.fooditem_id IS NOT NULL THEN fooditem END, 'remarks', ROW.remarks, 'selected_options', ROW.selected_options) INTO order_obj;
            orders := ARRAY_APPEND(orders, order_obj);
            IF ROW.total_price IS NOT NULL AND ROW.status = 'active' THEN
              total_order_price := total_order_price + ROW.total_price;
            END IF;
            IF ROW.user_price IS NOT NULL AND ROW.status = 'active' THEN
              IF currentUser IS NOT NULL AND ((currentUser::json->>'user_type')::int = 1) THEN
                total_user_paid := total_user_paid + ROW.user_paid;
              ELSE 
                total_user_paid := total_user_paid + ROW.user_price;
              END IF;
            END IF;
            IF ROW.restaurant_name != 'Beverages & More' AND ROW.status = 'active' THEN
              total_order_quantity := total_order_quantity + ROW.quantity;
              order_price_total := order_price_total + ROW.total_price;
            END IF;
            IF ROW.status = 'active' THEN
              total_quantity := total_quantity + ROW.quantity;
            END IF;
            IF ROW.status = 'cancelled' THEN
              cancelled_total_quantity := cancelled_total_quantity + ROW.quantity;
            END IF;
            IF ROW.restaurant_name IS NOT NULL THEN
              restaurants := ARRAY_APPEND(restaurants, ROW.restaurant_name::TEXT);
            END IF;
            IF ROW.status = 'active' AND ROW.invoice_id IS NOT NULL THEN
              p_invoice_id := ROW.invoice_id;
            END IF;
          END LOOP;
          SQL = 'SELECT runningmenu_name AS meeting_name, (CASE WHEN runningmenu_type=1 THEN ''lunch'' WHEN runningmenu_type=2 THEN ''dinner'' WHEN runningmenu_type=3 THEN ''breakfast'' END) AS meeting_type, 
          (CASE WHEN menu_type=1 THEN ''buffet'' ELSE ''individual'' END) AS meeting_style, (delivery_at AT TIME ZONE companies.time_zone) AS ordered_at, (cutoff_at AT TIME ZONE companies.time_zone) AS cutoff_at_timezone, (admin_cutoff_at AT TIME ZONE companies.time_zone) AS admin_cutoff_at_timezone, per_user_copay AS user_copay, 
          (CASE WHEN addresses.address_name IS NULL OR addresses.address_name = '''' THEN CONCAT_WS('': '', companies.name, CONCAT_WS('', '', CONCAT_WS('' '', NULLIF(addresses.street_number, ''''), addresses.street), NULLIF(addresses.suite_no, ''''), NULLIF(addresses.city, ''''))) ELSE CONCAT_WS('': '', addresses.address_name, CONCAT_WS('', '', CONCAT_WS('' '', NULLIF(addresses.street_number, ''''),addresses.street), NULLIF(addresses.suite_no, ''''), NULLIF(addresses.city, ''''))) END) AS formatted_address, TO_CHAR(delivery_at AT TIME ZONE companies.time_zone, ''HH24:MI'') AS end_time, marketplace, orders_count 
          FROM runningmenus 
          INNER JOIN companies ON companies.id = runningmenus.company_id 
          INNER JOIN addresses ON addresses.id = runningmenus.address_id
          WHERE runningmenus.id = '|| p_runningmenu_id ||' ';
          FOR ROW IN EXECUTE SQL
          LOOP
            invoice_download_link := p_backend_host || '/admin/invoices/' || p_invoice_id || '/generate_PDF.pdf';
            SELECT COALESCE(JSON_AGG(field), '[]') INTO runningmenu_fields FROM (SELECT fields.name, (CASE WHEN runningmenufields.field_type = 1 THEN runningmenufields.value ELSE fieldoptions.name END) AS value FROM runningmenufields INNER JOIN fields ON fields.id = runningmenufields.field_id LEFT JOIN fieldoptions ON fieldoptions.id = fieldoption_id WHERE runningmenufields.runningmenu_id = p_runningmenu_id ORDER BY fields.position ASC) AS field;
            SELECT SUM(line_items.amount) FROM line_items INTO delivery_fee WHERE line_items.invoice_id = p_invoice_id AND (item ILIKE '%delivery%');
            SELECT STRING_AGG(restaurant, ', ') INTO restaurants_names FROM (SELECT DISTINCT UNNEST(restaurants) AS restaurant) AS tbl;
            SELECT JSON_BUILD_OBJECT('meeting_name', ROW.meeting_name, 'meeting_type', ROW.meeting_type, 'meeting_style', ROW.meeting_style, 'ordered_at', ROW.ordered_at, 'cutoff_at', ROW.cutoff_at_timezone, 'admin_cutoff_at', ROW.admin_cutoff_at_timezone, 'user_copay', ROW.user_copay, 'sort_order', p_order_type, 'sort_type', p_order_by, 'formatted_address', ROW.formatted_address, 'delivery_fee', delivery_fee, 'invoice_download_link', invoice_download_link, 'restaurant_name', restaurants_names, 'total_price', CASE WHEN ((currentUser::json->>'user_type')::int = 2 OR (currentUser::json->>'user_type')::int = 6 OR (currentUser::json->>'user_type')::int = 7 OR p_share_meeting_id IS NOT NULL ) THEN total_user_paid ELSE (total_order_price-total_user_paid) END, 'end_time', ROW.end_time, 'total_quantity', total_quantity, 'cancelled_total_quantity', cancelled_total_quantity, 'marketplace', ROW.marketplace, 'price_per_head', CASE WHEN ROW.orders_count > 0 THEN ROUND(total_order_price/ROW.orders_count, 2) ELSE 0.00 END, 'avg_per_meal', CASE WHEN total_order_quantity > 0 THEN ROUND(order_price_total::DECIMAL/total_order_quantity, 2) ELSE 0.00 END, 'order_total', total_order_price, 'runningmenu_fields', runningmenu_fields) INTO runningmenu;
          END LOOP;
          -- Build the JSON Response:
          RETURN (SELECT JSON_BUILD_OBJECT(
              'enable_grouping_orders', (company::json->>'enable_grouping_orders'),
              'order_summary', runningmenu,
              'orders', orders
            )
          );
        END; $$
    LANGUAGE 'plpgsql';"
  end

  def self.down
    execute "DROP FUNCTION IF EXISTS sp_orders_detail(p_company_id INTEGER, p_address_id INTEGER, p_runningmenu_id INTEGER, p_backend_host TEXT, p_order_by TEXT, p_order_type TEXT, p_current_user_id INTEGER, p_share_meeting_id INTEGER)"
  end
end