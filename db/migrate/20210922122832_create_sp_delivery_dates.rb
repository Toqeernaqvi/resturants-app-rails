class CreateSpDeliveryDates < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION sp_delivery_dates(p_from TEXT, p_to TEXT, p_company_id INTEGER, p_current_user_id INTEGER)
    RETURNS JSON
    AS $$
    DECLARE
      ROW RECORD;
      ROW1 RECORD;
      runningmenu_types TEXT ARRAY DEFAULT ARRAY['dont_care', 'lunch', 'dinner', 'Side', 'breakfast'];
      currentUser JSON := NULL;
      hide_meeting_ids BIGINT[] := NULL;
      meeting JSON;
      meetings JSON[];
    BEGIN
      -- Set currentUser
      SELECT row_to_json(u) INTO currentUser
      FROM (SELECT * FROM users WHERE id = p_current_user_id) u;

      IF (currentUser::JSON->>'user_type')::INT = 2 OR (currentUser::JSON->>'user_type')::INT = 6 OR (currentUser::JSON->>'user_type')::INT = 7 THEN
        FOR ROW IN (SELECT runningmenus.id, runningmenus.slug, runningmenus.runningmenu_type, runningmenus.runningmenu_name, runningmenus.address_id, runningmenus.delivery_instructions, (runningmenus.delivery_at AT TIME ZONE companies.time_zone) AS delivery_at, runningmenus.hide_meeting, (CASE WHEN orders.user_id = p_current_user_id AND orders.status = 0 THEN true ELSE false END) placed_order, (CASE WHEN addresses.address_name IS NULL OR addresses.address_name = '' THEN CONCAT_WS(': ', companies.name, CONCAT_WS(', ', CONCAT_WS(' ', NULLIF(addresses.street_number, ''), addresses.street), NULLIF(addresses.suite_no, ''), NULLIF(addresses.city, ''))) ELSE CONCAT_WS(': ', addresses.address_name, CONCAT_WS(', ', CONCAT_WS(' ', NULLIF(addresses.street_number, ''),addresses.street), NULLIF(addresses.suite_no, ''), NULLIF(addresses.city, ''))) END) AS formatted_address FROM runningmenus 
        INNER JOIN companies ON companies.id = runningmenus.company_id
        INNER JOIN addresses ON addresses.id = runningmenus.address_id
        LEFT JOIN orders ON orders.runningmenu_id = runningmenus.id AND orders.user_id = p_current_user_id 
        WHERE runningmenus.status = 0 AND (addresses.status = 0) AND runningmenus.company_id = p_company_id AND (runningmenus.delivery_at BETWEEN p_from::timestamptz AND p_to::timestamptz) ORDER BY runningmenus.delivery_at ASC, placed_order desc)
        LOOP
          IF ROW.hide_meeting::BOOLEAN THEN
            hide_meeting_ids := ARRAY_APPEND(hide_meeting_ids, ROW.id);
            ELSE
            FOR ROW1 IN (
              SELECT (
                (SELECT COUNT(*) < 1 FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = ROW.id AND taggings.taggable_type = 'Runningmenu')
                OR
                (SELECT COUNT(*) > 0 FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = ROW.id AND taggings.taggable_type = 'Runningmenu' AND tags.id IN(SELECT tags.id FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = p_current_user_id AND taggings.taggable_type = 'User'))
              ) AS restrict
            )
            LOOP
              IF ROW1.restrict THEN
                SELECT JSON_BUILD_OBJECT('id', ROW.id, 'slug', ROW.slug, 'runningmenu_type', runningmenu_types[(ROW.runningmenu_type)::INT+1], 'runningmenu_name', ROW.runningmenu_name, 'address_id', ROW.address_id, 'delivery_instructions', ROW.delivery_instructions, 'delivery_at', ROW.delivery_at, 'placed_order', ROW.placed_order, 'formatted_address', ROW.formatted_address) INTO meeting;
                meetings := ARRAY_APPEND(meetings, meeting);
              END IF;
            END LOOP;
          END IF;
        END LOOP;
      ELSE
        FOR ROW IN (SELECT runningmenus.id, runningmenus.slug, runningmenus.runningmenu_type, runningmenus.runningmenu_name, runningmenus.address_id, runningmenus.delivery_instructions, (runningmenus.delivery_at AT TIME ZONE companies.time_zone) AS delivery_at, (CASE WHEN orders.status = 0 AND orders.runningmenu_id IS NOT NULL THEN true ELSE false END) placed_order, (CASE WHEN addresses.address_name IS NULL OR addresses.address_name = '' THEN CONCAT_WS(': ', companies.name, CONCAT_WS(', ', CONCAT_WS(' ', NULLIF(addresses.street_number, ''), addresses.street), NULLIF(addresses.suite_no, ''), NULLIF(addresses.city, ''))) ELSE CONCAT_WS(': ', addresses.address_name, CONCAT_WS(', ', CONCAT_WS(' ', NULLIF(addresses.street_number, ''),addresses.street), NULLIF(addresses.suite_no, ''), NULLIF(addresses.city, ''))) END) AS formatted_address  FROM runningmenus 
        INNER JOIN companies ON companies.id = runningmenus.company_id
        INNER JOIN addresses ON addresses.id = runningmenus.address_id
        LEFT OUTER JOIN orders ON orders.runningmenu_id = runningmenus.id
        WHERE runningmenus.status = 0 AND (addresses.status = 0) AND runningmenus.company_id = p_company_id AND (runningmenus.delivery_at BETWEEN p_from::timestamptz AND p_to::timestamptz) ORDER BY runningmenus.delivery_at ASC, placed_order desc)
        LOOP
          SELECT JSON_BUILD_OBJECT('id', ROW.id, 'slug', ROW.slug, 'runningmenu_type', runningmenu_types[(ROW.runningmenu_type)::INT+1], 'runningmenu_name', ROW.runningmenu_name, 'address_id', ROW.address_id, 'delivery_instructions', ROW.delivery_instructions, 'delivery_at', ROW.delivery_at, 'placed_order', ROW.placed_order, 'formatted_address', ROW.formatted_address) INTO meeting;
          meetings := ARRAY_APPEND(meetings, meeting);
        END LOOP;
      END IF;
      IF hide_meeting_ids IS NOT NULL THEN
        FOR ROW IN (SELECT runningmenus.id, runningmenus.slug, runningmenus.runningmenu_type, runningmenus.runningmenu_name, runningmenus.address_id, runningmenus.delivery_instructions, (runningmenus.delivery_at AT TIME ZONE companies.time_zone) AS delivery_at, (CASE WHEN orders.status = 0 AND orders.share_meeting_id IS NOT NULL THEN true ELSE false END) placed_order, (CASE WHEN addresses.address_name IS NULL OR addresses.address_name = '' THEN CONCAT_WS(': ', companies.name, CONCAT_WS(', ', CONCAT_WS(' ', NULLIF(addresses.street_number, ''), addresses.street), NULLIF(addresses.suite_no, ''), NULLIF(addresses.city, ''))) ELSE CONCAT_WS(': ', addresses.address_name, CONCAT_WS(', ', CONCAT_WS(' ', NULLIF(addresses.street_number, ''),addresses.street), NULLIF(addresses.suite_no, ''), NULLIF(addresses.city, ''))) END) AS formatted_address FROM runningmenus 
        INNER JOIN companies ON companies.id = runningmenus.company_id
        INNER JOIN addresses ON addresses.id = runningmenus.address_id
        INNER JOIN share_meetings ON share_meetings.runningmenu_id = runningmenus.id 
        LEFT JOIN orders ON orders.share_meeting_id = share_meetings.id WHERE runningmenus.id IN (SELECT * FROM unnest(hide_meeting_ids)) AND share_meetings.email = (currentUser::JSON)->>'email')
        LOOP
          SELECT JSON_BUILD_OBJECT('id', ROW.id, 'slug', ROW.slug, 'runningmenu_type', runningmenu_types[(ROW.runningmenu_type)::INT+1], 'runningmenu_name', ROW.runningmenu_name, 'address_id', ROW.address_id, 'delivery_instructions', ROW.delivery_instructions, 'delivery_at', ROW.delivery_at, 'placed_order', ROW.placed_order, 'formatted_address', ROW.formatted_address) INTO meeting;
          meetings := ARRAY_APPEND(meetings, meeting);
        END LOOP;
      END IF;
      RETURN (SELECT TO_JSON(meetings));
    END;
    $$ LANGUAGE plpgsql;"
  end

  def self.down
    execute "DROP FUNCTION IF EXISTS sp_delivery_dates(p_from TEXT, p_to TEXT, p_company_id INTEGER, p_current_user_id INTEGER)";
  end

end
