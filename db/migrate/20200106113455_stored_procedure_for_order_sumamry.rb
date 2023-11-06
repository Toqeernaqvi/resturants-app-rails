class StoredProcedureForOrderSumamry < ActiveRecord::Migration[5.1]
  def up
    execute "DROP FUNCTION IF EXISTS get_summary_detail(scheduler_id INT, addr_id INT, show_order_diff BOOLEAN, res_id INT, restaurant_addr_id INT, summary_check INT, scheduler_type INT, user_orders BOOLEAN, p_start_time TEXT, p_end_time TEXT);
    CREATE OR REPLACE FUNCTION get_summary_detail(scheduler_id INT, addr_id INT, show_order_diff BOOLEAN, res_id INT, restaurant_addr_id INT, summary_check INT, scheduler_type INT, user_orders BOOLEAN, p_start_time TEXT DEFAULT NULL, p_end_time TEXT DEFAULT NULL)
    RETURNS TABLE (
      id BIGINT, runningmenu_id BIGINT, restaurant_address_id BIGINT, number_of_meals INTEGER, food_price_total NUMERIC(8,2), sales_tax_rate NUMERIC(8,4), sales_tax NUMERIC(12,6), restaurant_commission NUMERIC(12,6), restaurant_payout NUMERIC(12,6), dish_title TEXT, dish_price NUMERIC(8,2), serve_count INTEGER, menu_type INTEGER, order_grouping BOOLEAN, driver_name TEXT, short_code TEXT , restaurant_name TEXT, order_ids TEXT, order_status TEXT, order_group TEXT, fooditem_name TEXT, fooditem_price NUMERIC(8,2), fooditem_notes_to_restaurant TEXT, fooditem_description TEXT, restaurant_location TEXT,  company_location TEXT, remarks TEXT, options TEXT, options_price NUMERIC, dietary_name TEXT, ingredient_name TEXT, delivery_instructions TEXT, quantity BIGINT, email TEXT, user_name TEXT, event TEXT, version_id BIGINT
    )
    AS $$
    DECLARE
      ROW RECORD;
      SQL TEXT;
      meeting JSON := NULL;
    BEGIN
      SELECT row_to_json(m) INTO meeting FROM (SELECT status FROM runningmenus WHERE runningmenus.id = scheduler_id) m;
      SQL = 'SELECT orders.runningmenu_id, orders.restaurant_address_id, orders.share_meeting_id, orders.user_id, ';
      IF user_orders THEN
        SQL = SQL || ' orders.id, ';
      END IF;
      SQL = SQL || ' SUM(orders.number_of_meals) AS number_of_meals, SUM(orders.food_price_total) AS food_price_total, orders.sales_tax_rate, SUM(orders.sales_tax) AS sales_tax, SUM(orders.restaurant_commission) AS restaurant_commission, SUM(orders.restaurant_payout) AS restaurant_payout, dishsizes.title AS dish_title, (SELECT dishsize_fooditems.price from dishsize_fooditems WHERE dishsize_fooditems.fooditem_id = fooditems.id AND dishsize_fooditems.dishsize_id= dishsizes.id) AS dish_price, dishsizes.serve_count, runningmenus.menu_type, companies.enable_grouping_orders AS order_grouping, CONCAT(drivers.first_name, '' '', drivers.last_name) AS driver_name, addresses.short_code AS short_code,restaurants.name AS  restaurant_name';
      IF show_order_diff AND NOT(user_orders) THEN
        SQL = SQL || ',Array_to_string(Array_agg(orders.id), '', '') AS order_ids, (CASE WHEN orders.status = 0 THEN ''active'' ELSE ''cancelled'' END)::TEXT AS order_status';
      ELSIF user_orders THEN
        SQL = SQL || ', orders.id::TEXT AS order_ids, (CASE WHEN orders.status = 0 THEN ''active'' ELSE ''cancelled'' END)::TEXT AS order_status';
      ELSE
        SQL = SQL || ', orders.id::TEXT AS order_ids, (CASE WHEN orders.status = 0 THEN ''active'' ELSE ''cancelled'' END)::TEXT AS order_status';
      END IF;
      IF user_orders THEN
        SQL = SQL || ', (CASE WHEN (share_meetings.first_name != '''' OR share_meetings.last_name != '''') THEN CONCAT(share_meetings.first_name, '' '' , share_meetings.last_name) ELSE CONCAT(users.first_name, '' '' , users.last_name) END) AS user_name, share_meetings.email';
      END IF;
      SQL = SQL || ', string_agg(orders.group, '','') AS order_group, fooditems.name AS fooditem_name, orders.food_price AS fooditem_price, fooditems.notes_to_restaurant AS fooditem_notes_to_restaurant, fooditems.description AS fooditem_description, (SELECT CONCAT(restaurants.name, '': '' , addresses.address_line) FROM addresses WHERE addresses.id = orders.restaurant_address_id) AS restaurant_location,
      CONCAT(companies.name, '': '' , addresses.address_line) AS company_location, orders.remarks, (
      SELECT string_agg( CONCAT(options.description, ''$'', options.price), '', '')
      FROM options
      INNER JOIN options_orders ON options.id=options_orders.option_id
      INNER JOIN optionsets_orders ON options_orders.optionsets_order_id=optionsets_orders.id
      INNER JOIN orders AS o ON optionsets_orders.order_id=o.id
      WHERE o.id = orders.id
      ) AS options, (
      SELECT SUM(options.price)
      FROM options
      INNER JOIN options_orders ON options.id=options_orders.option_id
      INNER JOIN optionsets_orders ON options_orders.optionsets_order_id=optionsets_orders.id
      INNER JOIN orders AS o ON optionsets_orders.order_id=o.id
      WHERE o.id = orders.id
      ) AS options_price, (
      SELECT string_agg(dietaries.name, '','')
      FROM dietaries
      INNER JOIN dietaries_fooditems ON dietaries_fooditems.dietary_id = dietaries.id
      INNER JOIN fooditems AS fi ON dietaries_fooditems.fooditem_id = fi.id
      WHERE fi.id = fooditems.id
      ) AS dietary_name, (
      SELECT string_agg(ingredients.name, '','')
      FROM ingredients
      INNER JOIN fooditems_ingredients ON fooditems_ingredients.ingredient_id = ingredients.id
      INNER JOIN fooditems AS fi ON fooditems_ingredients.fooditem_id = fi.id
      WHERE fi.id = fooditems.id
      ) AS ingredient_name, runningmenus.delivery_instructions, SUM(orders.quantity) AS quantity';
      IF show_order_diff THEN
        SQL = SQL || ', (CASE WHEN orders.latest_version_id IS NULL THEN NULL ELSE orders.latest_version_id END)::BIGINT AS version_id';
      ELSE
        SQL = SQL || ', NULL::BIGINT AS version_id';
      END IF;
      IF show_order_diff AND (NOT(summary_check > 0)) THEN
        SQL = SQL || ', (CASE WHEN (orders.status = 1) and (versions.event = ''update'') THEN ''delete'' ELSE versions.event END)::TEXT AS event';
      ELSE
        SQL = SQL || ', '''' AS event';
      END IF;
      SQL = SQL || ' FROM orders';
      IF user_orders THEN
        SQL = SQL || ' LEFT JOIN share_meetings ON orders.share_meeting_id = share_meetings.id
        INNER JOIN users ON orders.user_id = users.id';
      END IF;
      SQL = SQL || ' INNER JOIN runningmenus ON orders.runningmenu_id = runningmenus.id
      LEFT JOIN drivers ON runningmenus.driver_id = drivers.id
      LEFT JOIN dishsizes ON orders.dishsize_id = dishsizes.id
      INNER JOIN companies ON runningmenus.company_id = companies.id
      INNER JOIN addresses ON runningmenus.address_id = addresses.id
      INNER JOIN fooditems ON orders.fooditem_id = fooditems.id
      INNER JOIN restaurants ON orders.restaurant_id = restaurants.id';
      IF show_order_diff AND (NOT(summary_check > 0)) THEN
        IF (meeting::json->>'status')::INT = 2 THEN
          SQL = SQL || ' LEFT JOIN versions ON orders.latest_version_id = versions.id';
        ELSE
          IF p_start_time IS NOT NULL AND p_end_time IS NOT NULL THEN
            SQL = SQL || ' INNER JOIN versions ON orders.latest_version_id = versions.id AND versions.created_at BETWEEN ''' || p_start_time::timestamptz || ''' AND ''' || p_end_time ::timestamptz || ''' AND versions.whodunnit IN (SELECT users.email FROM users INNER JOIN companies ON companies.id = users.company_id INNER JOIN runningmenus ON runningmenus.company_id = companies.id WHERE users.user_type = 1 AND (users.confirmed_at IS NOT NULL) AND users.status = 0 AND runningmenus.id = ' || scheduler_id || ')';
          ELSE
            SQL = SQL || ' INNER JOIN versions ON orders.latest_version_id = versions.id AND versions.whodunnit IN (SELECT users.email FROM users INNER JOIN companies ON companies.id = users.company_id INNER JOIN runningmenus ON runningmenus.company_id = companies.id WHERE users.user_type = 1 AND (users.confirmed_at IS NOT NULL) AND users.status = 0 AND runningmenus.id = ' || scheduler_id || ')';
          END IF;
        END IF;
      END IF;
      SQL = SQL || ' WHERE 1=1';
      IF show_order_diff AND NOT(summary_check > 0) THEN
        IF (meeting::json->>'status')::INT = 2 THEN
          SQL = SQL || ' AND orders.parent_status = 0';
        ELSE
          SQL = SQL || ' AND orders.latest_version_id IS NOT NULL';
        END IF;
      ELSE
        SQL = SQL || ' AND orders.status =  0';
      END IF;
      IF res_id > 0 AND addr_id > 0 THEN
        SQL = SQL || ' AND orders.restaurant_id = ' || res_id || ' AND runningmenus.address_id = ' || addr_id;
      END IF;

      IF show_order_diff AND restaurant_addr_id > 0 AND NOT(summary_check > 0) THEN
        IF (meeting::json->>'status')::INT = 2 THEN
          SQL = SQL || ' AND orders.parent_status = 0';
        ELSE
          SQL = SQL || ' AND orders.latest_version_id IS NOT NULL';
        END IF;
      END IF;
      SQL = SQL || ' AND restaurants.status = 0 AND orders.runningmenu_id =' || scheduler_id;
      IF restaurant_addr_id > 0 THEN
        SQL = SQL || ' AND orders.restaurant_address_id =' || restaurant_addr_id;
      END IF;
      IF user_orders THEN
        SQL = SQL || 'GROUP BY orders.id, dishsizes.id, fooditems.id, runningmenus.id, companies.id, addresses.id, restaurants.id, drivers.id, share_meetings.id, users.id, event';
      ELSE
        SQL = SQL || ' GROUP BY runningmenus.menu_type, restaurant_id, fooditem_id, remarks, options, options_price, runningmenus.address_id, runningmenus.company_id, orders.runningmenu_id, orders.restaurant_address_id,
        options_price, runningmenus.delivery_instructions, driver_name, orders.id, order_grouping, orders.group, dish_title, dish_price, dishsizes.serve_count, orders.number_of_meals, orders.food_price_total, orders.sales_tax_rate, orders.sales_tax, orders.restaurant_commission, orders.restaurant_payout, addresses.short_code, restaurants.name, fooditems.name, orders.food_price,
        fooditems.notes_to_restaurant, fooditems.description, companies.name, addresses.address_line, fooditems.id, event';
      END IF;
      IF show_order_diff THEN
        SQL = SQL || ',orders.status, orders.latest_version_id';
      END IF;
      IF scheduler_type = 1 THEN
        SQL = SQL || ', orders.dishsize_id';
      END IF;
      IF scheduler_type = 1 THEN
        SQL = SQL || ' ORDER BY dishsizes.title ASC';
      ELSE
        SQL = SQL ||  ' ORDER BY restaurant_name ASC, fooditem_name ASC';
      END IF;
      FOR ROW IN EXECUTE SQL LOOP
        IF user_orders THEN
          id := row.id::BIGINT;
          email := row.email::TEXT;
          user_name := row.user_name::TEXT;
        END IF;
        runningmenu_id := row.runningmenu_id::BIGINT;
        restaurant_address_id := row.restaurant_address_id::BIGINT;
        number_of_meals := row.number_of_meals::INTEGER ;
        food_price_total := row.food_price_total::NUMERIC(8,2) ;
        sales_tax_rate := row.sales_tax_rate::NUMERIC(8,4) ;
        sales_tax := row.sales_tax::NUMERIC(12,6) ;
        restaurant_commission := row.restaurant_commission::NUMERIC(12,6) ;
        restaurant_payout := row.restaurant_payout::NUMERIC(12,6) ;
        dish_title := row.dish_title::TEXT ;
        dish_price := row.dish_price::NUMERIC(8,2) ;
        serve_count := row.serve_count::INTEGER ;
        menu_type := row.menu_type::INTEGER ;
        order_grouping := row.order_grouping::BOOLEAN ;
        driver_name := row.driver_name::TEXT ;
        short_code := row.short_code::TEXT ;
        restaurant_name := row.restaurant_name::TEXT ;
        order_ids := row.order_ids::TEXT ;
        order_status := row.order_status::TEXT ;
        order_group := row.order_group::TEXT ;
        fooditem_name := row.fooditem_name::TEXT ;
        fooditem_price := row.fooditem_price::NUMERIC(8,2) ;
        fooditem_notes_to_restaurant := row.fooditem_notes_to_restaurant::TEXT ;
        fooditem_description := row.fooditem_description::TEXT ;
        restaurant_location := row.restaurant_location::TEXT ;
        company_location := row.company_location::TEXT ;
        remarks:= row.remarks::TEXT ;
        options := row.options::TEXT ;
        options_price := row.options_price::NUMERIC ;
        dietary_name :=  row.dietary_name::TEXT;
        ingredient_name := row.ingredient_name::TEXT;
        delivery_instructions := row.delivery_instructions::TEXT;
        quantity := row.quantity::BIGINT;
        event := row.event::TEXT;
        version_id := row.version_id::BIGINT;
        RETURN NEXT;
      END LOOP;
    END; $$

    LANGUAGE 'plpgsql';"
  end

  def down
    execute "DROP FUNCTION IF EXISTS get_summary_detail(scheduler_id INT, addr_id INT, show_order_diff BOOLEAN, res_id INT, restaurant_addr_id INT, summary_check INT, scheduler_type INT, user_orders BOOLEAN, p_start_time TEXT, p_end_time TEXT)";
  end
end
