class CreateRepVendorsChart < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION rep_vendors_chart(p_start_date DATE, p_end_date DATE, p_company_ids TEXT DEFAULT NULL, p_address_ids TEXT DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
          SQL TEXT := '';
          total_vendors DECIMAL := 0.0;
          rep_vendor_graph JSON;
          rep_vendors_graph JSON[];
          rep_obj RECORD;
        BEGIN
          -- Top vendors chart data
          SQL = 'SELECT (COUNT(*)::DECIMAL) AS total FROM rep_vendors WHERE dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          FOR rep_obj IN EXECUTE SQL
          LOOP
            IF rep_obj.total IS NOT NULL THEN
              total_vendors := rep_obj.total::DECIMAL;
            END IF;
          END LOOP;
          SQL = 'SELECT cuisine, ROUND((COUNT(cuisine)::DECIMAL/(' || total_vendors || ') * 100), 2) AS percentage FROM (';
          SQL = SQL || 'SELECT name, cuisine FROM rep_vendors WHERE dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          SQL = SQL || ') AS tbl GROUP BY tbl.cuisine';
          FOR rep_obj IN EXECUTE SQL
          LOOP
            SELECT JSON_BUILD_OBJECT('id', rep_obj.cuisine, 'label', rep_obj.cuisine, 'value', rep_obj.percentage) INTO rep_vendor_graph;
            rep_vendors_graph := ARRAY_APPEND(rep_vendors_graph, rep_vendor_graph);
          END LOOP;

          -- Build the JSON Response:
          RETURN (SELECT JSON_BUILD_OBJECT(
              'vendors_graph', COALESCE(rep_vendors_graph, ARRAY[]::json[])
            )
          );
        END; $$
    LANGUAGE 'plpgsql';"
  end

  def self.down
    execute "DROP FUNCTION rep_vendors_chart(p_start_date DATE, p_end_date DATE, p_company_ids TEXT, p_address_ids TEXT)"
  end
end
