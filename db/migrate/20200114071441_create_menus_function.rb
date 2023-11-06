class CreateMenusFunction < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION menus(p_s3_base_url TEXT ,p_runningmenu_id INTEGER, p_company_id INTEGER, p_share_meeting_id INTEGER DEFAULT NULL, p_current_user_id INTEGER DEFAULT NULL, p_r TEXT DEFAULT NULL, p_d TEXT DEFAULT NULL, p_i TEXT DEFAULT NULL)
      RETURNS JSON
      AS $$
      DECLARE
        s3_url TEXT := p_s3_base_url || '/uploads/fooditem/image';
        s3_image_url TEXT := p_s3_base_url || '/uploads/image/image';
        logo_url TEXT := p_s3_base_url || '/uploads/address/logo';
        logo_url_ingredient TEXT := p_s3_base_url || '/uploads/ingredient/logo';
        logo_url_dietary TEXT := p_s3_base_url || '/uploads/dietary/logo';
        fooditem_image_url TEXT := NULL;
        currentUser JSON := NULL;
        runningmenu JSON;
        runningmenutype INT;
        menutype INT;
        company JSON;
        section_types TEXT ARRAY DEFAULT ARRAY['Appetizer', 'Entrée', 'Vegetarian Entrée', 'Side', 'Dessert'];
        restaurants JSON[];
        rest JSON;
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
        remaining_amount DECIMAL := 0.0;
        global_avg_rating DECIMAL := 0.0;
        share_meeting_remaining_amount DECIMAL := 0.0;
        scheduler_budget DECIMAL := 0.0;
        in_budget BOOLEAN := TRUE;
        ordered_quantity INTEGER := 0;
        img_obj JSON;
        thumb_obj JSON;
        medium_obj JSON;
        restaurant_cuisines JSON;
      BEGIN
        -- Set currentUser
        IF p_current_user_id IS NOT NULL THEN
          SELECT row_to_json(u) INTO currentUser
          FROM (SELECT * FROM users WHERE id = p_current_user_id) u;
        END IF;
        -- Load the company:
        SELECT row_to_json(comp) INTO company
        FROM (SELECT * FROM companies WHERE companies.id = p_company_id) comp;        
        -- Load the runningmenu:
        SELECT ROW_TO_JSON(r) INTO runningmenu
        FROM (SELECT runningmenu_type, menu_type, per_meal_budget, per_user_copay FROM runningmenus WHERE id = p_runningmenu_id) AS r;
        menutype := runningmenu::JSON->>'menu_type';
        runningmenutype := runningmenu::JSON->>'runningmenu_type';
        SELECT ROUND(AVG(rating_value), 2) INTO global_avg_rating FROM ratings WHERE ratings.rating_value > 0 AND ratings.ratingable_type = 'Fooditem';
        SQL = 'SELECT restaurants.id, restaurants.name, addresses.id AS address_id, restaurants.average_rating, CASE WHEN addresses.logo IS NULL THEN addresses.logo ELSE CONCAT(''' || logo_url || ''', ''/'', addresses.id, ''/'', addresses.logo) END AS logo_url,(SELECT (COUNT(*) <= 0) AS new_restaurant_ina_year FROM runningmenus INNER JOIN addresses_runningmenus ON runningmenus.id = addresses_runningmenus.runningmenu_id AND runningmenus.company_id = ' || p_company_id || ' AND runningmenus.delivery_at BETWEEN NOW() - INTERVAL ''1 year'' AND NOW() - INTERVAL ''1 days'' WHERE(addresses_runningmenus.address_id = addresses.id)),(SELECT (COUNT(*) <= 0) AS new_restaurant_ina_week FROM runningmenus INNER JOIN addresses_runningmenus ON runningmenus.id = addresses_runningmenus.runningmenu_id AND runningmenus.company_id = ' || p_company_id || ' AND runningmenus.created_at BETWEEN NOW() - INTERVAL ''7 days'' AND NOW() - INTERVAL ''1 days'' WHERE(addresses_runningmenus.address_id = addresses.id)) FROM addresses INNER JOIN addresses_runningmenus ON addresses.id = addresses_runningmenus.address_id INNER JOIN restaurants ON restaurants.id = addresses.addressable_id AND addresses.addressable_type = ''Restaurant'' WHERE addresses_runningmenus.dynamic_section_id IS NULL AND addresses_runningmenus.runningmenu_id = ' || p_runningmenu_id;
        IF p_r IS NOT NULL THEN
         SQL = SQL || ' AND restaurants.id IN(' || p_r || ') ORDER BY restaurants.average_rating DESC, addresses_runningmenus.rank ASC';
        ELSE
          SQL = SQL || ' ORDER BY restaurants.average_rating DESC, addresses_runningmenus.rank ASC';
        END IF;
        FOR restaurant IN EXECUTE SQL
        LOOP
          sects := NULL;
          sections := NULL;
          IF menutype > 0 AND (p_share_meeting_id IS NOT NULL OR (p_current_user_id IS NOT NULL AND ((currentUser::JSON->>'user_type')::INT = 2 OR (currentUser::JSON->>'user_type')::INT = 6 OR (currentUser::JSON->>'user_type')::INT = 7 ) )) THEN
            f_sections := buffet_sections(s3_url, p_runningmenu_id, restaurant.address_id::INT, company);
          ELSE
            SECTION_SQL = 'SELECT sections.id, sections.name, sections.description, section_type FROM sections INNER JOIN menus ON sections.menu_id = menus.id WHERE menus.status = 0 AND sections.status = 0 AND menus.menu_type = ' || (CASE WHEN menutype = 1 THEN 4 ELSE runningmenutype END) || ' AND menus.address_id = ' || restaurant.address_id;
            SECTION_SQL = SECTION_SQL || ' ORDER BY sections.section_type';
            FOR section IN EXECUTE SECTION_SQL
            LOOP
              food_items := NULL;
              food_item := NULL;
              SQL = 'SELECT DISTINCT fooditems.id, fooditems.name, fooditems.description, fooditems.spicy, fooditems.best_seller, fooditems.price, fooditems.gross_price, fooditems.skip_markup, fooditems.ignore_budget, fooditems.rating_count, fooditems.average_rating, fooditems.image IS NULL, fooditems.average_rating, CASE WHEN (fooditems.created_at BETWEEN NOW() - INTERVAL ''7 days'' AND NOW()) AND NOT ''' || restaurant.new_restaurant_ina_week || ''' THEN true::boolean ELSE false::boolean END AS new_fooditem, CASE WHEN fooditems.image IS NULL THEN fooditems.image ELSE CONCAT(''' || s3_url || ''', ''/'', fooditems.id, ''/'', fooditems.image) END AS image_url, CASE WHEN fooditems.image IS NULL THEN fooditems.image ELSE CONCAT(''' || s3_url || ''', ''/'', fooditems.id, ''/'', ''medium_'', fooditems.image) END AS image_medium_url, CASE WHEN fooditems.image IS NULL THEN fooditems.image ELSE CONCAT(''' || s3_url || ''', ''/'', fooditems.id, ''/'', ''thumb_'', fooditems.image) END AS image_thumb_url, favorites.user_id IS NOT NULL AS user_favorite FROM fooditems INNER JOIN fooditems_sections ON fooditems.id = fooditems_sections.fooditem_id LEFT JOIN favorites ON fooditems.id = favorites.favoritable_id AND favorites.favoritable_type =''Fooditem'' AND favorites.user_id = ' || p_current_user_id || ' ';
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
              SQL = SQL || ' AND fooditems_sections.section_id = ' || section.id || ' AND fooditems.status = 0 ORDER BY fooditems.image IS NULL, fooditems.average_rating DESC';

              FOR fooditem IN EXECUTE SQL
              LOOP
                options_sets := NULL;
                optionset_obj := NULL;
                medium_obj := NULL;
                thumb_obj := NULL;
                img_obj := NULL;
                in_budget := TRUE;
                fooditem_nutritions := NULL;
                IF p_current_user_id IS NOT NULL AND (currentUser::JSON->>'user_type')::INT = 2 THEN
                  SELECT COALESCE(CAST(SUM(orders.total_price) AS DECIMAL), 0.0) INTO remaining_amount FROM orders INNER JOIN runningmenus ON runningmenus.id = orders.runningmenu_id WHERE orders.runningmenu_id = p_runningmenu_id AND orders.status = 0 AND (runningmenus.company_id = p_company_id AND orders.user_id = p_current_user_id);
                END IF;
                IF p_share_meeting_id IS NOT NULL THEN
                  SELECT COALESCE(CAST(SUM(orders.total_price) AS DECIMAL), 0.0) INTO share_meeting_remaining_amount FROM orders INNER JOIN runningmenus ON runningmenus.id = orders.runningmenu_id WHERE orders.runningmenu_id = p_runningmenu_id AND orders.status = 0 AND (runningmenus.company_id = p_company_id AND orders.share_meeting_id = p_share_meeting_id);
                END IF;
                -- SET scheduler budget
                SELECT CAST( (runningmenu::JSON->>'per_meal_budget')::DECIMAL + CASE WHEN (company::JSON->>'reduced_markup_check')::BOOLEAN AND (company::JSON->>'reduced_markup')::INT > 0 AND NOT (company::JSON->>'enable_saas')::BOOLEAN THEN (company::JSON->>'markup')::DECIMAL * (company::JSON->>'reduced_markup')::INT / 100 ELSE 0 END AS DECIMAL) INTO scheduler_budget;
                IF menutype > 0
                OR ( fooditem.ignore_budget AND (p_current_user_id IS NOT NULL AND (currentUser::JSON->>'user_type')::INT = 1) )
                OR (p_current_user_id IS NOT NULL AND ((currentUser::JSON->>'user_type')::INT = 1 OR (currentUser::JSON->>'user_type')::INT = 7))
                AND ( ( CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN fooditem.gross_price ELSE fooditem.gross_price + (company::JSON->>'markup')::DECIMAL END ) <= (CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN (runningmenu::JSON->>'per_meal_budget')::DECIMAL ELSE scheduler_budget END) OR (runningmenu::JSON->>'per_user_copay')::INT > 0 )
                OR ((p_current_user_id IS NOT NULL AND ((currentUser::JSON->>'user_type')::INT = 2 OR (currentUser::JSON->>'user_type')::INT = 6) ) AND ((runningmenu::JSON->>'per_user_copay')::INT > 0 OR (CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN fooditem.gross_price ELSE (fooditem.gross_price + (company::JSON->>'markup')::DECIMAL) END <= CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN (runningmenu::JSON->>'per_meal_budget')::DECIMAL ELSE scheduler_budget END )))
                OR (p_share_meeting_id IS NOT NULL AND ((runningmenu::JSON->>'per_user_copay')::INT > 0 OR ( CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN fooditem.gross_price ELSE (fooditem.gross_price + (company::JSON->>'markup')::DECIMAL) END ) <= ( CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN (runningmenu::JSON->>'per_meal_budget')::DECIMAL ELSE scheduler_budget END ) ) ) THEN

                  IF ( p_current_user_id IS NOT NULL AND ((currentUser::JSON->>'user_type')::INT = 2 OR (currentUser::JSON->>'user_type')::INT = 6) AND (runningmenu::JSON->>'per_user_copay')::INT = 0 AND ((( CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN fooditem.gross_price ELSE (fooditem.gross_price + (company::JSON->>'markup')::DECIMAL ) END ) > (( CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN (runningmenu::JSON->>'per_meal_budget')::DECIMAL ELSE scheduler_budget END ) - remaining_amount) ))) OR ( p_share_meeting_id IS NOT NULL AND (runningmenu::JSON->>'per_user_copay')::INT = 0 AND (( CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN fooditem.gross_price ELSE (fooditem.gross_price + (company::JSON->>'markup')::DECIMAL ) END )) > (( CASE WHEN fooditem.skip_markup OR (company::JSON->>'enable_saas')::BOOLEAN THEN (runningmenu::JSON->>'per_meal_budget')::DECIMAL ELSE scheduler_budget END) - share_meeting_remaining_amount)) THEN
                    in_budget := FALSE;
                  END IF;
                  SELECT COALESCE(CAST(SUM(orders.quantity) AS INTEGER), 0) INTO ordered_quantity FROM orders INNER JOIN runningmenus ON runningmenus.id = orders.runningmenu_id WHERE orders.runningmenu_id = p_runningmenu_id AND orders.status = 0 AND (runningmenus.company_id = p_company_id) AND orders.fooditem_id = fooditem.id;
                  -- Load dietaries
                  SELECT COALESCE(JSON_AGG(dietry), '[]') INTO dietaries
                  FROM (SELECT d.id, d.name, d.enable_user_to_filter, d.logo, d.alt_logo FROM dietaries AS d
                    INNER  JOIN dietaries_fooditems ON d.id = dietaries_fooditems.dietary_id
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

                  SELECT JSON_BUILD_OBJECT('url', fooditem.image_medium_url) INTO medium_obj;
                  SELECT JSON_BUILD_OBJECT('url', fooditem.image_thumb_url) INTO thumb_obj;
                  SELECT JSON_BUILD_OBJECT('url', fooditem.image_url, 'medium', medium_obj, 'thumb', thumb_obj) INTO img_obj;
                  IF options_sets IS NOT NULL THEN
                    SELECT JSON_BUILD_OBJECT('id', fooditem.id, 'name', fooditem.name, 'description', fooditem.description, 'price', fooditem.price, 'gross_price', fooditem.gross_price, 'spicy', fooditem.spicy, 'best_seller', fooditem.best_seller, 'skip_markup', fooditem.skip_markup, 'rating_count', fooditem.rating_count, 'average_rating', fooditem.average_rating, 'global_avg_rating', global_avg_rating, 'image', img_obj, 'restaurant_name', restaurant.name, 'in_budget', in_budget, 'new_fooditem', fooditem.new_fooditem, 'ordered_quantity', ordered_quantity, 'dietaries', dietaries, 'ingredients', ingredients, 'dishsizes', dishsizes, 'optionsets', options_sets, 'nutritions', fooditem_nutritions, 'user_favorite', fooditem.user_favorite) INTO food_item;
                  ELSE
                    SELECT JSON_BUILD_OBJECT('id', fooditem.id, 'name', fooditem.name, 'description', fooditem.description, 'price', fooditem.price, 'gross_price', fooditem.gross_price, 'spicy', fooditem.spicy, 'best_seller', fooditem.best_seller, 'skip_markup', fooditem.skip_markup, 'rating_count', fooditem.rating_count, 'average_rating', fooditem.average_rating, 'global_avg_rating', global_avg_rating, 'image', img_obj, 'restaurant_name', restaurant.name, 'in_budget', in_budget, 'new_fooditem', fooditem.new_fooditem, 'ordered_quantity', ordered_quantity, 'dietaries', dietaries, 'ingredients', ingredients, 'dishsizes', dishsizes, 'optionsets', '[]'::JSON, 'nutritions', fooditem_nutritions, 'user_favorite', fooditem.user_favorite) INTO food_item;
                  END IF;
                END IF;
                IF food_item IS NOT NULL THEN
                  food_items := array_append(food_items, food_item);
                  food_item := NULL;
                END IF;
              END LOOP;
              IF food_items IS NOT NULL THEN
                IF menutype > 0 THEN
                  SELECT JSON_BUILD_OBJECT('id', section.id, 'name', section.name, 'description', section.description, 'section_type', section_types[section.section_type+1],  'section_name', section.name, 'fooditems', food_items) INTO sects;
                ELSE
                  SELECT JSON_BUILD_OBJECT('id', section.id, 'name', section.name, 'description', section.description, 'fooditems', food_items) INTO sects;
                END IF;
                sections := array_append(sections, sects);
              END IF;
            END LOOP;
            SELECT COALESCE(TO_JSON(sections), '[]') INTO f_sections;
          END IF;
          SELECT TO_JSON(STRING_AGG(cuisines.name, ', ')) INTO restaurant_cuisines FROM cuisines INNER JOIN cuisines_restaurants ON cuisines.id = cuisines_restaurants.cuisine_id WHERE cuisines_restaurants.restaurant_id = restaurant.id;
          SELECT JSON_BUILD_OBJECT('id', restaurant.id, 'name', restaurant.name, 'average_rating', restaurant.average_rating, 'cuisines', restaurant_cuisines, 'address_id', restaurant.address_id, 'logo_url', restaurant.logo_url, 'restaurant_used_ina_year', restaurant.new_restaurant_ina_year, 'restaurant_create_inlast_week', restaurant.new_restaurant_ina_week,'sections', f_sections) INTO rest;
          restaurants := array_append(restaurants, rest);
        END LOOP;
        -- Build the JSON Response:
        RETURN (SELECT JSON_BUILD_OBJECT(
            'restaurants', restaurants
          )
        );

      END; $$
    LANGUAGE 'plpgsql';"
  end
  def self.down
    execute "DROP FUNCTION IF EXISTS menus(p_s3_base_url TEXT, p_runningmenu_id INTEGER, p_company_id INTEGER, p_share_meeting_id INTEGER, p_current_user_id INTEGER, p_r TEXT, p_d TEXT, p_i TEXT)"
  end
end
