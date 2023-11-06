class CreateRepChordGraph < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION rep_chord_graph(p_start_date DATE, p_end_date DATE, p_company_ids TEXT DEFAULT NULL, p_address_ids TEXT DEFAULT NULL, p_restaurant_ids TEXT DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
          SQL TEXT := '';
          total_vendors DECIMAL := 0.0;
          rep_chord_graph JSON;
          rep_chords_graph JSON[];
          rep_obj RECORD;
        BEGIN
          SQL = 'SELECT name, company_name, SUM(total_spent) AS total FROM (';
          SQL = SQL || 'SELECT name, total_spent, company_name FROM rep_vendors WHERE dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          IF p_restaurant_ids IS NOT NULL THEN
            SQL = SQL || ' AND restaurant_id IN(' || p_restaurant_ids || ')';
          END IF;
          SQL = SQL || ' GROUP BY name, company_name, total_spent, dated_on) AS tbl GROUP BY name, company_name ORDER BY total desc';
          FOR rep_obj IN EXECUTE SQL
          LOOP
            SELECT JSON_BUILD_OBJECT('restaurant', rep_obj.name, 'total_spent', rep_obj.total, 'company_name', rep_obj.company_name) INTO rep_chord_graph;
            rep_chords_graph := ARRAY_APPEND(rep_chords_graph, rep_chord_graph);
          END LOOP;

          -- Build the JSON Response:
          RETURN (SELECT JSON_BUILD_OBJECT(
              'chord_graph', COALESCE(rep_chords_graph, ARRAY[]::json[])
            )
          );
        END; $$
    LANGUAGE 'plpgsql';"
  end

  def self.down
    execute "DROP FUNCTION rep_chord_graph(p_start_date DATE, p_end_date DATE, p_company_ids TEXT, p_address_ids TEXT, p_restaurant_ids TEXT)"
  end
end
