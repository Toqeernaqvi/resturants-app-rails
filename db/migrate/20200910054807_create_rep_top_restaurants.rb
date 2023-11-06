class CreateRepTopRestaurants < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION rep_top_restaurants(p_start_date DATE, p_end_date DATE, p_company_ids TEXT DEFAULT NULL, p_address_ids TEXT DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
          SQL TEXT := '';
          total_vendors DECIMAL := 0.0;
          rep_chord_graph JSON;
          rep_chords_graph JSON[];
          rep_obj RECORD;
        BEGIN
          SQL = 'SELECT restaurant_id, name, SUM(total_spent) AS total FROM (';
          SQL = SQL || 'SELECT restaurant_id, name, string_agg(DISTINCT cuisine, '', '') AS cuisine, total_spent FROM rep_vendors WHERE dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          SQL = SQL || ' GROUP BY restaurant_id, name, total_spent) AS tbl GROUP BY restaurant_id, name ORDER BY SUM(total_spent) DESC LIMIT 10';
          FOR rep_obj IN EXECUTE SQL
          LOOP
            SELECT JSON_BUILD_OBJECT('restaurant_id', rep_obj.restaurant_id, 'restaurant', rep_obj.name, 'total_spent', rep_obj.total) INTO rep_chord_graph;
            rep_chords_graph := ARRAY_APPEND(rep_chords_graph, rep_chord_graph);
          END LOOP;

          -- Build the JSON Response:
          RETURN (SELECT JSON_BUILD_OBJECT(
              'restaurants', COALESCE(rep_chords_graph, ARRAY[]::json[])
            )
          );
        END; $$
    LANGUAGE 'plpgsql';"
  end

  def self.down
    execute "DROP FUNCTION rep_top_restaurants(p_start_date DATE, p_end_date DATE, p_company_ids TEXT, p_address_ids TEXT)"
  end
end
