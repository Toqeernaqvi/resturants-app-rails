class CreateBuffetSectionsFunction < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION buffet_sections(p_s3_url TEXT, p_runningmenu_id INTEGER, p_address_id INTEGER, p_company JSON)
      RETURNS JSON
      AS $$
      DECLARE
        section RECORD;
        section_types TEXT ARRAY DEFAULT ARRAY['Appetizer', 'Entrée', 'Vegetarian Entrée', 'Side', 'Dessert'];
        fooditem JSON;
        r_section JSON;
        sections JSON[];
        sects JSON;
        food_items JSON[];
        food_item JSON;
        dietaries JSON;
        ingredients JSON;
        option RECORD;
        options TEXT;
        img_obj JSON;
        thumb_obj JSON;
        medium_obj JSON;
      BEGIN
        FOR section IN SELECT JSON_BUILD_ARRAY(JSON_BUILD_OBJECT('section_type', sections.section_type, 'name', sections.name)) AS section_arr, JSON_AGG(JSON_BUILD_OBJECT('id', fooditems.id, 'name', fooditems.name, 'description', fooditems.description, 'calories', fooditems.calories, 'spicy', fooditems.spicy, 'best_seller', fooditems.best_seller, 'order_id', orders.id, 'average_rating', fooditems.average_rating, 'restaurant_name', restaurants.name, 'image_url', CASE WHEN fooditems.image IS NULL THEN fooditems.image ELSE CONCAT(p_s3_url, '/', fooditems.id, '/', fooditems.image) END, 'image_medium_url', CASE WHEN fooditems.image IS NULL THEN fooditems.image ELSE CONCAT(p_s3_url, '/', fooditems.id, '/', 'medium_', fooditems.image) END, 'image_thumb_url', CASE WHEN fooditems.image IS NULL THEN fooditems.image ELSE CONCAT(p_s3_url, '/', fooditems.id, '/', 'thumb_', fooditems.image) END) ORDER BY sections.section_type ASC, fooditems.image IS NULL, fooditems.average_rating DESC) AS fooditems_arr FROM orders INNER JOIN restaurants ON orders.restaurant_id = restaurants.id INNER JOIN fooditems ON fooditems.id = orders.fooditem_id INNER JOIN fooditems_sections ON fooditems_sections.fooditem_id = fooditems.id INNER JOIN sections ON sections.id = fooditems_sections.section_id WHERE orders.status = 0 AND orders.restaurant_address_id = p_address_id AND orders.runningmenu_id = p_runningmenu_id GROUP BY sections.section_type, sections.name
        LOOP          
          food_items := NULL;
          FOR fooditem IN SELECT * FROM JSON_ARRAY_ELEMENTS(section.fooditems_arr)
          LOOP
            food_item := NULL;
            medium_obj := NULL;
            thumb_obj := NULL;
            img_obj := NULL;
            -- Load dietaries
            SELECT COALESCE(JSON_AGG(dietry), '[]') INTO dietaries
            FROM (SELECT d.id, d.name FROM dietaries AS d 
              INNER JOIN dietaries_fooditems ON d.id = dietaries_fooditems.dietary_id
              WHERE dietaries_fooditems.fooditem_id = (fooditem->>'id')::INT
            ) dietry;
            -- Load ingredients
            SELECT COALESCE(JSON_AGG(ingredient), '[]') INTO ingredients
            FROM (SELECT ingredients.id, ingredients.name FROM ingredients INNER JOIN fooditems_ingredients ON ingredients.id = fooditems_ingredients.ingredient_id WHERE fooditems_ingredients.fooditem_id = (fooditem->>'id')::INT) ingredient;
            -- Load options
            FOR option IN SELECT string_agg(options.description, ', ') AS description FROM optionsets_orders INNER JOIN options_orders ON options_orders.optionsets_order_id = optionsets_orders.id INNER JOIN options ON options.id = options_orders.option_id WHERE optionsets_orders.order_id = (fooditem->>'order_id')::INT AND (options.description IS NOT NULL)
            LOOP
              options := option.description;
            END LOOP;
            SELECT JSON_BUILD_OBJECT('url', fooditem->'image_medium_url') INTO medium_obj;
            SELECT JSON_BUILD_OBJECT('url', fooditem->'image_thumb_url') INTO thumb_obj;
            SELECT JSON_BUILD_OBJECT('url', fooditem->'image_url', 'medium', medium_obj, 'thumb', thumb_obj) INTO img_obj;
            SELECT JSON_BUILD_OBJECT('id', fooditem->>'id', 'name', fooditem->'name', 'description', fooditem->'description', 'calories', fooditem->'calories', 'spicy', fooditem->'spicy', 'best_seller', fooditem->'best_seller', 'average_rating', fooditem->'average_rating', 'image', img_obj, 'restaurant_name', fooditem->'restaurant_name', 'options', options, 'dietaries', dietaries, 'ingredients', ingredients) INTO food_item;
            IF food_item IS NOT NULL THEN
              food_items := ARRAY_APPEND(food_items, food_item);
            END IF;  
          END LOOP;
          FOR r_section IN SELECT * FROM JSON_ARRAY_ELEMENTS(section.section_arr)
          LOOP
            IF food_items IS NOT NULL THEN
              SELECT JSON_BUILD_OBJECT('section_type', section_types[(r_section->>'section_type')::INT+1],  'section_name', r_section->>'name', 'fooditems', food_items) INTO sects;
              sections := ARRAY_APPEND(sections, sects);
            END IF;  
          END LOOP;          
        END LOOP;
        RETURN (SELECT TO_JSON(sections));
      END; $$
    LANGUAGE 'plpgsql';"
  end
  def self.down
    execute "DROP FUNCTION buffet_sections(p_s3_url TEXT, p_runningmenu_id INTEGER, p_address_id INTEGER, p_company JSON)"
  end
end
