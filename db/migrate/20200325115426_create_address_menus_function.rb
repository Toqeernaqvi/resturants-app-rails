class CreateAddressMenusFunction < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION address_menus(p_s3_base_url TEXT, p_address_id INTEGER, p_company_id INTEGER, p_menu_type INTEGER, p_current_user_id INTEGER, p_r TEXT DEFAULT NULL, p_d TEXT DEFAULT NULL, p_i TEXT DEFAULT NULL)
      RETURNS JSON
      AS $$
      DECLARE
        s3_url TEXT := p_s3_base_url || '/uploads/fooditem/image';
        logo_url TEXT := p_s3_base_url || '/uploads/address/logo';
        section_types TEXT ARRAY DEFAULT ARRAY['Appetizer', 'Entrée', 'Vegetarian Entrée', 'Side', 'Dessert'];
        company JSON;
        restaurants JSON[];
        rest JSON;
        clone_orders JSON;
        SQL TEXT := '';
        SECTION_SQL TEXT := '';
        restaurant RECORD;
        section RECORD;
        fooditem RECORD;
        sections JSON[];
        f_sections JSON;
        sects JSON;
        food_items JSON[];
        food_item JSON;
        dietaries JSON;
        nutrition RECORD;
        fooditem_nutrition JSON;
        childs JSON;
        fooditem_nutritions JSON[];
        ingredients JSON;
        dishsizes JSON;
        options JSON;
        optionset RECORD;
        optionset_obj JSON;
        options_sets JSON[];
        in_budget BOOLEAN := TRUE;
        ordered_quantity INTEGER := 0;
        img_obj JSON;
        thumb_obj JSON;
        medium_obj JSON;
        company_budget DECIMAL := 0.0;
        contact_image_url TEXT := NULL;
        row RECORD;
        runningmenu RECORD;
        order_counter INT := 0;
        order_ids BIGINT[];
        field_options JSON;
        custom_fields JSON[];
        custom_field JSON;
        enable_saas BOOLEAN;
        restaurant_cuisines JSON;
      BEGIN        
        -- Load the company:
        SELECT row_to_json(comp) INTO company
        FROM (SELECT * FROM companies WHERE companies.id = p_company_id) comp;
        enable_saas := (company::JSON->>'enable_saas')::BOOLEAN;
        SQL = 'SELECT DISTINCT restaurants.id, (CASE WHEN restaurants.name = ''Beverages & More'' THEN 1 ELSE 0 END), restaurants.name, addresses.id AS address_id, restaurants.average_rating, addresses.enable_self_service, CASE WHEN addresses.logo IS NULL THEN addresses.logo ELSE CONCAT(''' || logo_url || ''', ''/'', addresses.id, ''/'', addresses.logo) END AS logo_url,(SELECT (COUNT(*) <= 0) AS new_restaurant_ina_year FROM runningmenus INNER JOIN addresses_runningmenus ON runningmenus.id = addresses_runningmenus.runningmenu_id AND runningmenus.company_id = ' || p_company_id || ' AND runningmenus.delivery_at BETWEEN NOW() - INTERVAL ''1 year'' AND NOW() - INTERVAL ''1 days'' WHERE(addresses_runningmenus.address_id = addresses.id)),(SELECT (COUNT(*) <= 0) AS new_restaurant_ina_week FROM runningmenus INNER JOIN addresses_runningmenus ON runningmenus.id = addresses_runningmenus.runningmenu_id AND runningmenus.company_id = ' || p_company_id || ' AND runningmenus.created_at BETWEEN NOW() - INTERVAL ''7 days'' AND NOW() - INTERVAL ''1 days'' WHERE(addresses_runningmenus.address_id = addresses.id)) FROM addresses INNER JOIN addresses_runningmenus ON addresses.id = addresses_runningmenus.address_id INNER JOIN restaurants ON restaurants.id = addresses.addressable_id AND addresses.addressable_type = ''Restaurant'' WHERE (CASE WHEN '''|| enable_saas ||''' THEN addresses.id = ''' || p_address_id || ''' ELSE (addresses.id = ''' || p_address_id || ''' OR restaurants.name = ''Beverages & More'') END)';
        IF p_r IS NOT NULL THEN
         SQL = SQL || ' AND restaurants.id IN(' || p_r || ') ORDER BY (CASE WHEN restaurants.name = ''Beverages & More'' THEN 1 ELSE 0 END) ASC';
        ELSE
          SQL = SQL || ' ORDER BY (CASE WHEN restaurants.name = ''Beverages & More'' THEN 1 ELSE 0 END) ASC';
        END IF;
        FOR restaurant IN EXECUTE SQL
        LOOP
          contact_image_url := restaurant.logo_url;
          sects := NULL;
          sections := NULL;
          SECTION_SQL = 'SELECT sections.id, sections.name, sections.description, section_type FROM sections INNER JOIN menus ON sections.menu_id = menus.id WHERE menus.status = 0 AND sections.status = 0 AND menus.menu_type = ' || p_menu_type || ' AND menus.address_id = ' || restaurant.address_id;
          SECTION_SQL = SECTION_SQL || ' ORDER BY sections.section_type';
          FOR section IN EXECUTE SECTION_SQL
          LOOP
            food_items := NULL;
            food_item := NULL;
            SQL = 'SELECT DISTINCT fooditems.id, fooditems.name, fooditems.description, fooditems.spicy, fooditems.best_seller, fooditems.price, fooditems.gross_price, fooditems.skip_markup, fooditems.ignore_budget, fooditems.rating_count, fooditems.average_rating, fooditems.image, CASE WHEN (fooditems.created_at BETWEEN NOW() - INTERVAL ''7 days'' AND NOW()) AND NOT ''' || restaurant.new_restaurant_ina_week || ''' THEN true::boolean ELSE false::boolean END AS new_fooditem, CASE WHEN fooditems.image IS NULL THEN fooditems.image ELSE CONCAT(''' || s3_url || ''', ''/'', fooditems.id, ''/'', fooditems.image) END AS image_url, CASE WHEN fooditems.image IS NULL THEN fooditems.image ELSE CONCAT(''' || s3_url || ''', ''/'', fooditems.id, ''/'', ''medium_'', fooditems.image) END AS image_medium_url, CASE WHEN fooditems.image IS NULL THEN fooditems.image ELSE CONCAT(''' || s3_url || ''', ''/'', fooditems.id, ''/'', ''thumb_'', fooditems.image) END AS image_thumb_url, favorites.user_id IS NOT NULL AS user_favorite FROM fooditems INNER JOIN fooditems_sections ON fooditems.id = fooditems_sections.fooditem_id LEFT JOIN favorites ON fooditems.id = favorites.favoritable_id AND favorites.favoritable_type =''Fooditem'' AND favorites.user_id = ' || p_current_user_id || ' ';
            IF p_d IS NOT NULL THEN
              IF p_i IS NOT NULL THEN
                SQL = SQL || ' INNER JOIN dietaries_fooditems ON dietaries_fooditems.fooditem_id = fooditems.id INNER JOIN fooditems_ingredients ON fooditems_ingredients.fooditem_id = fooditems.id WHERE dietaries_fooditems.dietary_id IN(' || p_d || ') AND fooditems_ingredients.ingredient_id IN(' || p_i || ')';
              ELSE
                SQL = SQL || ' INNER JOIN dietaries_fooditems ON dietaries_fooditems.fooditem_id = fooditems.id WHERE dietaries_fooditems.dietary_id IN(' || p_d || ')';
              END IF;
            ELSE
              IF p_i IS NOT NULL THEN
                SQL = SQL || ' INNER JOIN fooditems_ingredients ON fooditems_ingredients.fooditem_id = fooditems.id WHERE fooditems_ingredients.ingredient_id IN(' || p_i || ')';
              ELSE
                SQL = SQL || ' WHERE 1=1 ';
              END IF;
            END IF;
            SQL = SQL || ' AND fooditems_sections.section_id = ' || section.id || ' AND fooditems.status = 0 ORDER BY fooditems.image ASC';

            FOR fooditem IN EXECUTE SQL
            LOOP
              options_sets := NULL;
              optionset_obj := NULL;
              medium_obj := NULL;
              thumb_obj := NULL;
              img_obj := NULL;
              in_budget := TRUE;
              fooditem_nutritions := NULL;
              -- SET company budget
              SELECT CAST( (company::JSON->>'user_meal_budget')::DECIMAL + CASE WHEN (company::JSON->>'reduced_markup_check')::BOOLEAN AND (company::JSON->>'reduced_markup')::INT > 0 AND NOT (company::JSON->>'enable_saas')::BOOLEAN THEN (company::JSON->>'markup')::DECIMAL * (company::JSON->>'reduced_markup')::INT / 100 ELSE 0 END AS DECIMAL) INTO company_budget;
              IF p_menu_type = 4 OR fooditem.ignore_budget OR ( (CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN fooditem.gross_price ELSE fooditem.gross_price + (company::JSON->>'markup')::DECIMAL END ) <= (CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN (company::JSON->>'user_meal_budget')::DECIMAL ELSE company_budget END) OR (company::JSON->>'user_copay')::INT > 0 ) THEN
                -- Load dietaries
                SELECT COALESCE(JSON_AGG(dietry), '[]') INTO dietaries
                FROM (SELECT d.id, d.name, d.enable_user_to_filter, d.logo, d.alt_logo FROM dietaries AS d
                  INNER JOIN dietaries_fooditems ON d.id = dietaries_fooditems.dietary_id
                  WHERE dietaries_fooditems.fooditem_id = fooditem.id
                ) dietry;
                -- Load ingredients
                SELECT COALESCE(JSON_AGG(ingredient), '[]') INTO ingredients
                FROM (SELECT ingredients.id, ingredients.name, ingredients.enable_user_to_filter, ingredients.logo, ingredients.alt_logo FROM ingredients INNER JOIN fooditems_ingredients ON ingredients.id = fooditems_ingredients.ingredient_id WHERE fooditems_ingredients.fooditem_id = fooditem.id) ingredient;
                -- Load dishsizes
                SELECT COALESCE(JSON_AGG(dishsize), '[]') INTO dishsizes
                FROM (SELECT dishsizes.id, dishsizes.title, dishsizes.description, dishsizes.serve_count, (dishsize_fooditems.price + (CASE WHEN (fooditem.skip_markup)::boolean OR (company::JSON->>'enable_saas')::BOOLEAN THEN 0 ELSE (dishsize_fooditems.price * (company::json->>'buffet_addons_markup')::DECIMAL )/100 END)) price  FROM dishsizes INNER JOIN dishsize_fooditems ON dishsizes.id = dishsize_fooditems.dishsize_id WHERE dishsize_fooditems.fooditem_id = fooditem.id AND dishsizes.status = 0) dishsize;
                -- Load optionsets
                FOR optionset IN (SELECT DISTINCT optionsets.id, optionsets.name, optionsets.required, optionsets.start_limit, optionsets.end_limit FROM optionsets INNER JOIN options ON options.optionset_id = optionsets.id INNER JOIN fooditems_optionsets ON optionsets.id = fooditems_optionsets.optionset_id WHERE options.status = 0 AND optionsets.status = 0 AND fooditems_optionsets.fooditem_id = fooditem.id)
                LOOP
                  optionset_obj := NULL;
                  options := NULL;
                  SELECT COALESCE(JSON_AGG(optionset_option), '[]') INTO options
                  FROM (SELECT id, description, price FROM options WHERE options.optionset_id = optionset.id AND options.status = 0 ORDER BY position ASC) optionset_option;
                  -- IF optionset_obj IS NOT NULL THEN
                    SELECT JSON_BUILD_OBJECT('id', optionset.id, 'name', optionset.name, 'required', optionset.required, 'start_limit', optionset.start_limit, 'end_limit', optionset.end_limit, 'options', options) INTO optionset_obj;
                    options_sets := array_append(options_sets, optionset_obj);
                  -- END IF;
                END LOOP;
                -- Load nutritions
                FOR nutrition IN (SELECT nutritional_facts.id AS id, nutritions.id AS nutrition_id, nutritions.name, nutritional_facts.value FROM nutritions INNER JOIN nutritional_facts ON nutritions.id = nutritional_facts.nutrition_id WHERE nutritional_facts.factable_id = fooditem.id AND nutritional_facts.factable_type = 'Fooditem' AND nutritional_facts.value > 0 AND (nutritions.parent_id IS NULL) ORDER BY nutritional_facts.id ASC)
                LOOP
                  SELECT COALESCE(JSON_AGG(nutrition_childs), '[]') INTO childs
                  FROM (SELECT nutritional_facts.id, nutritions.name, nutritional_facts.value FROM nutritional_facts INNER JOIN nutritions ON nutritions.id = nutritional_facts.nutrition_id WHERE nutritional_facts.factable_type = 'Fooditem' AND nutritional_facts.factable_id = fooditem.id AND nutritional_facts.value > 0 AND nutritions.parent_id = nutrition.nutrition_id ORDER BY nutritional_facts.id ASC) nutrition_childs;
                  
                  SELECT JSON_BUILD_OBJECT('id', nutrition.id, 'name', nutrition.name, 'nutrition_id', nutrition.nutrition_id, 'value', nutrition.value, 'childs', childs) INTO fooditem_nutrition;
                  fooditem_nutritions := array_append(fooditem_nutritions, fooditem_nutrition);
                END LOOP;
                IF contact_image_url IS NULL THEN
                  contact_image_url := fooditem.image_medium_url;
                END IF;
                SELECT JSON_BUILD_OBJECT('url', fooditem.image_medium_url) INTO medium_obj;
                SELECT JSON_BUILD_OBJECT('url', fooditem.image_thumb_url) INTO thumb_obj;
                SELECT JSON_BUILD_OBJECT('url', fooditem.image_url, 'medium', medium_obj, 'thumb', thumb_obj) INTO img_obj;
                IF options_sets IS NOT NULL THEN
                  SELECT JSON_BUILD_OBJECT('id', fooditem.id, 'name', fooditem.name, 'description', fooditem.description, 'price', fooditem.price, 'gross_price', fooditem.gross_price, 'spicy', fooditem.spicy, 'best_seller', fooditem.best_seller, 'skip_markup', fooditem.skip_markup, 'rating_count', fooditem.rating_count, 'average_rating', fooditem.average_rating, 'image', img_obj, 'restaurant_name', restaurant.name, 'in_budget', in_budget, 'new_fooditem', fooditem.new_fooditem, 'ordered_quantity', ordered_quantity, 'dietaries', dietaries, 'ingredients', ingredients, 'dishsizes', dishsizes, 'optionsets', options_sets, 'nutritions', fooditem_nutritions, 'user_favorite', fooditem.user_favorite) INTO food_item;
                ELSE
                  SELECT JSON_BUILD_OBJECT('id', fooditem.id, 'name', fooditem.name, 'description', fooditem.description, 'price', fooditem.price, 'gross_price', fooditem.gross_price, 'spicy', fooditem.spicy, 'best_seller', fooditem.best_seller, 'skip_markup', fooditem.skip_markup, 'rating_count', fooditem.rating_count, 'average_rating', fooditem.average_rating, 'image', img_obj, 'restaurant_name', restaurant.name, 'in_budget', in_budget, 'new_fooditem', fooditem.new_fooditem, 'ordered_quantity', ordered_quantity, 'dietaries', dietaries, 'ingredients', ingredients, 'dishsizes', dishsizes, 'optionsets', '[]'::JSON, 'nutritions', fooditem_nutritions, 'user_favorite', fooditem.user_favorite) INTO food_item;
                END IF;
              END IF;

              IF food_item IS NOT NULL THEN
                food_items := array_append(food_items, food_item);
                food_item := NULL;
              END IF;
            END LOOP;
            IF food_items IS NOT NULL THEN
              IF p_menu_type = 4 THEN
                SELECT JSON_BUILD_OBJECT('id', section.id, 'name', section.name, 'description', section.description, 'section_type', section_types[section.section_type+1],  'section_name', section.name, 'fooditems', food_items) INTO sects;
              ELSE
                SELECT JSON_BUILD_OBJECT('id', section.id, 'name', section.name, 'description', section.description, 'fooditems', food_items) INTO sects;
              END IF;
              sections := array_append(sections, sects);
            END IF;
          END LOOP;
          SELECT COALESCE(TO_JSON(sections), '[]') INTO f_sections;
          IF EXISTS(SELECT  1 AS one FROM fields WHERE fields.company_id = p_company_id AND (status = 0) AND fields.required = 1 LIMIT 1) THEN
            FOR row IN SELECT fields.*, (CASE WHEN field_type = 0 THEN 'dropdown' ELSE 'text' END) AS field_type_str FROM fields WHERE fields.company_id = p_company_id AND (status = 0)
            LOOP
              field_options := NULL;
              IF row.field_type = 0 THEN
                SELECT JSON_AGG(f) INTO field_options
                FROM(SELECT id, name FROM fieldoptions WHERE fieldoptions.field_id = row.id AND fieldoptions.status = 0 ORDER BY fieldoptions.position ASC) AS f;
              END IF;
              SELECT JSON_BUILD_OBJECT('id', row.id, 'field_type', row.field_type_str, 'name', row.name, 'required', row.required, 'options', field_options) INTO custom_field;
              custom_fields := array_append(custom_fields, custom_field);
            END LOOP;
          END IF;
          SELECT TO_JSON(STRING_AGG(cuisines.name, ', ')) INTO restaurant_cuisines FROM cuisines INNER JOIN cuisines_restaurants ON cuisines.id = cuisines_restaurants.cuisine_id WHERE cuisines_restaurants.restaurant_id = restaurant.id;
          SELECT JSON_BUILD_OBJECT('id', restaurant.id, 'name', restaurant.name, 'average_rating', restaurant.average_rating, 'cuisines', restaurant_cuisines, 'address_id', restaurant.address_id, 'logo_url', restaurant.logo_url, 'restaurant_used_ina_year', restaurant.new_restaurant_ina_year, 'restaurant_create_inlast_week', restaurant.new_restaurant_ina_week, 'custom_fields', custom_fields, 'sections', f_sections) INTO rest;
          restaurants := array_append(restaurants, rest);
        END LOOP;
        clone_orders := NULL;
        FOR runningmenu IN SELECT runningmenus.id, (runningmenus.delivery_at AT TIME ZONE companies.time_zone) delivery_at_timezone FROM runningmenus INNER JOIN companies on companies.id = runningmenus.company_id INNER JOIN orders ON orders.runningmenu_id = runningmenus.id AND orders.status = 0 AND orders.restaurant_address_id = p_address_id WHERE runningmenus.status = 0 AND runningmenus.company_id = p_company_id AND (CASE WHEN p_menu_type > 3 THEN runningmenus.menu_type = 1 ELSE runningmenus.menu_type = 0 AND runningmenus.runningmenu_type = p_menu_type END) AND (runningmenus.delivery_at < NOW()) ORDER BY runningmenus.delivery_at DESC LIMIT 1
        LOOP
          FOR row IN SELECT orders.* FROM orders INNER JOIN fooditems ON fooditems.id = orders.fooditem_id WHERE orders.runningmenu_id = runningmenu.id AND orders.status = 0 AND orders.restaurant_address_id = p_address_id AND fooditems.status = 0
          LOOP
            IF EXISTS (SELECT optionsets_orders.* FROM optionsets_orders WHERE optionsets_orders.order_id = row.id) THEN
              IF NOT EXISTS (SELECT optionsets.* FROM optionsets INNER JOIN optionsets_orders ON optionsets.id = optionsets_orders.optionset_id WHERE optionsets_orders.order_id = row.id AND optionsets.status = 1) AND NOT EXISTS (SELECT optionsets_orders.* FROM optionsets_orders INNER JOIN options_orders ON options_orders.optionsets_order_id = optionsets_orders.id INNER JOIN options ON options.id = options_orders.option_id WHERE optionsets_orders.order_id = row.id AND options.status = 1) THEN
                order_counter := order_counter+1;
                order_ids := ARRAY_APPEND(order_ids, row.id);
              END IF;
            ELSE
              order_counter := order_counter+1;
              order_ids := ARRAY_APPEND(order_ids, row.id);
            END IF;
          END LOOP;
          SELECT JSON_BUILD_OBJECT('delivery_at', runningmenu.delivery_at_timezone, 'orders_count', order_counter, 'order_ids', order_ids) INTO clone_orders;
        END LOOP;
        -- Build the JSON Response:
        RETURN (SELECT JSON_BUILD_OBJECT('restaurants', restaurants, 'clone_orders', clone_orders));

      END; $$
    LANGUAGE 'plpgsql';"
  end
  def self.down
    execute "DROP FUNCTION IF EXISTS address_menus(p_s3_base_url TEXT, p_address_id INTEGER, p_company_id INTEGER, p_menu_type INTEGER, p_current_user_id INTEGER, p_r TEXT, p_d TEXT, p_i TEXT)"
  end
end
