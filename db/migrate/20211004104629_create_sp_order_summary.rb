class CreateSpOrderSummary < ActiveRecord::Migration[5.1]
  def up
    execute "CREATE OR REPLACE FUNCTION sp_order_summary(p_runningmenu_id INTEGER, p_company_address_id INTEGER, p_restaurant_id INTEGER, p_restaurant_address_id INTEGER, p_group_orders BOOLEAN DEFAULT TRUE)
    RETURNS TABLE (
      id BIGINT, runningmenu_id BIGINT, restaurant_address_id BIGINT, number_of_meals INTEGER, food_price_total NUMERIC(8,2), sales_tax_rate NUMERIC(8,4), sales_tax NUMERIC(12,6), restaurant_commission NUMERIC(12,6), restaurant_payout NUMERIC(12,6), dish_title TEXT, dish_price NUMERIC(8,2), serve_count INTEGER, menu_type INTEGER, order_grouping BOOLEAN, driver_name TEXT, short_code TEXT , restaurant_name TEXT, order_group TEXT, fooditem_name TEXT, fooditem_price NUMERIC(8,2), fooditem_notes_to_restaurant TEXT, fooditem_description TEXT, restaurant_location TEXT,  company_location TEXT, remarks TEXT, options TEXT, options_price NUMERIC, dietary_name TEXT, ingredient_name TEXT, delivery_instructions TEXT, quantity BIGINT, email TEXT, user_name TEXT, user_type TEXT, order_status TEXT
    )
    AS $$
    DECLARE
      ROW RECORD;
      SQL TEXT;
      meeting JSON := NULL;
    BEGIN
      SELECT row_to_json(m) INTO meeting FROM (SELECT runningmenus.menu_type AS r_menu_type, status FROM runningmenus WHERE runningmenus.id = p_runningmenu_id) m;
      IF p_group_orders THEN
        SQL = 'SELECT 0::BIGINT AS id, ';
      ELSE
        SQL = 'SELECT orders.id::BIGINT, ';
      END IF;
      SQL = SQL || 'STRING_AGG(orders.group, '','') AS order_group, STRING_AGG(DISTINCT orders.remarks, '','') AS remarks,
      STRING_AGG( DISTINCT CASE WHEN (users.user_type = 2 OR orders.share_meeting_id IS NOT NULL) THEN ''user'' WHEN orders.guest_id IS NOT NULL THEN ''guest'' WHEN users.user_type = 7 THEN ''unsubsidized user'' WHEN users.user_type = 6 THEN ''company manager'' ELSE ''admin'' END, '','') AS user_type,
      STRING_AGG( DISTINCT CASE WHEN orders.share_meeting_id IS NOT NULL THEN CONCAT(share_meetings.first_name, '' '' , share_meetings.last_name) WHEN orders.guest_id IS NOT NULL THEN CONCAT(guests.first_name, '' '' , guests.last_name) ELSE CONCAT(users.first_name, '' '' , users.last_name) END, '','') AS user_name,
      STRING_AGG( DISTINCT COALESCE(share_meetings.email, ''''), '','') AS email, SUM(orders.quantity) AS quantity, SUM(orders.number_of_meals) AS number_of_meals, SUM(orders.food_price_total) AS food_price_total, SUM(orders.sales_tax) AS sales_tax,
      SUM(orders.restaurant_commission) AS restaurant_commission, SUM(orders.restaurant_payout) AS restaurant_payout, orders.sales_tax_rate, orders.runningmenu_id, orders.restaurant_address_id, CONCAT(companies.name, '': '' , addresses.address_line) AS company_location, fooditems.name AS fooditem_name, orders.food_price AS fooditem_price, fooditems.notes_to_restaurant AS fooditem_notes_to_restaurant, fooditems.description AS fooditem_description,
      dishsizes.title AS dish_title, (SELECT dishsize_fooditems.price from dishsize_fooditems WHERE dishsize_fooditems.fooditem_id = fooditems.id AND dishsize_fooditems.dishsize_id= dishsizes.id) AS dish_price,
      dishsizes.serve_count, runningmenus.menu_type, runningmenus.delivery_instructions, companies.enable_grouping_orders AS order_grouping, CONCAT(drivers.first_name, '' '', drivers.last_name) AS driver_name, addresses.short_code,restaurants.name AS  restaurant_name,      
      (SELECT CONCAT(restaurants.name, '': '' , addresses.address_line) FROM addresses WHERE addresses.id = orders.restaurant_address_id) AS restaurant_location,
      (SELECT STRING_AGG( CONCAT(options.description, ''$'', options.price), '', '') FROM options
      INNER JOIN options_orders ON options.id=options_orders.option_id
      INNER JOIN optionsets_orders ON options_orders.optionsets_order_id=optionsets_orders.id
      INNER JOIN orders AS o ON optionsets_orders.order_id=o.id
      WHERE o.id = orders.id
      ) AS options,
      (SELECT SUM(options.price) FROM options
      INNER JOIN options_orders ON options.id=options_orders.option_id
      INNER JOIN optionsets_orders ON options_orders.optionsets_order_id=optionsets_orders.id
      INNER JOIN orders AS o ON optionsets_orders.order_id=o.id
      WHERE o.id = orders.id
      ) AS options_price,
      (SELECT STRING_AGG(dietaries.name, '','') FROM dietaries
      INNER JOIN dietaries_fooditems ON dietaries_fooditems.dietary_id = dietaries.id
      INNER JOIN fooditems AS fi ON dietaries_fooditems.fooditem_id = fi.id
      WHERE fi.id = fooditems.id
      ) AS dietary_name,
      (SELECT STRING_AGG(ingredients.name, '','') FROM ingredients
      INNER JOIN fooditems_ingredients ON fooditems_ingredients.ingredient_id = ingredients.id
      INNER JOIN fooditems AS fi ON fooditems_ingredients.fooditem_id = fi.id
      WHERE fi.id = fooditems.id
      ) AS ingredient_name
      
      FROM orders
      INNER JOIN runningmenus ON orders.runningmenu_id = runningmenus.id
      INNER JOIN companies ON runningmenus.company_id = companies.id
      INNER JOIN addresses ON runningmenus.address_id = addresses.id
      INNER JOIN fooditems ON orders.fooditem_id = fooditems.id
      INNER JOIN restaurants ON orders.restaurant_id = restaurants.id
      LEFT JOIN share_meetings ON orders.share_meeting_id = share_meetings.id
      LEFT JOIN guests ON orders.guest_id = guests.id
      LEFT JOIN users ON orders.user_id = users.id
      LEFT JOIN drivers ON runningmenus.driver_id = drivers.id
      LEFT JOIN dishsizes ON orders.dishsize_id = dishsizes.id

      WHERE 1=1';
      IF (meeting::json->>'status')::INT = 2 THEN
        SQL = SQL || ' AND orders.parent_status = 0';
      ELSE
        SQL = SQL || ' AND orders.status =  0';
      END IF;
      IF p_restaurant_id > 0 AND p_company_address_id > 0 THEN
        SQL = SQL || ' AND orders.restaurant_id = ' || p_restaurant_id || ' AND runningmenus.address_id = ' || p_company_address_id;
      END IF;

      SQL = SQL || ' AND restaurants.status = 0 AND orders.runningmenu_id =' || p_runningmenu_id;
      IF p_restaurant_address_id > 0 THEN
        SQL = SQL || ' AND orders.restaurant_address_id =' || p_restaurant_address_id;
      END IF;

      IF p_group_orders THEN
        SQL = SQL || ' GROUP BY runningmenus.menu_type, restaurant_id, fooditem_id, remarks, options, options_price, runningmenus.address_id, runningmenus.company_id,
        orders.runningmenu_id, orders.restaurant_address_id, options_price, runningmenus.delivery_instructions, driver_name, order_grouping,
        dish_title, dish_price, dishsizes.serve_count, orders.sales_tax_rate, addresses.short_code, restaurants.name, orders.food_price, companies.name, addresses.address_line, fooditems.id';
      ELSE
        SQL = SQL || 'GROUP BY orders.id, dishsizes.id, fooditems.id, runningmenus.id, companies.id, addresses.id, restaurants.id, drivers.id, share_meetings.id, users.id';
      END IF;

      IF (meeting::json->>'r_menu_type')::INT = 1 THEN
        SQL = SQL || ', orders.dishsize_id';
      END IF;
      IF (meeting::json->>'r_menu_type')::INT = 1 THEN
        SQL = SQL || ' ORDER BY dishsizes.title ASC';
      ELSE
        SQL = SQL ||  ' ORDER BY restaurant_name ASC, fooditem_name ASC, id ASC';
      END IF;
      
      FOR ROW IN EXECUTE SQL LOOP
        id := row.id::BIGINT;
        email := row.email::TEXT;
        user_type := row.user_type::TEXT;
        user_name := row.user_name::TEXT;
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
        order_status := 'active'::TEXT;
        RETURN NEXT;
      END LOOP;
    END; $$

    LANGUAGE 'plpgsql';"
  end

  def down
    execute "DROP FUNCTION IF EXISTS sp_order_summary(p_runningmenu_id INTEGER, p_company_address_id INTEGER, p_restaurant_id INTEGER, p_restaurant_address_id INTEGER, p_group_orders BOOLEAN)";
  end
end
