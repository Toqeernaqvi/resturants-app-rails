class CreateRepTopVendorsWithPagination < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION rep_top_vendors(p_limit INTEGER, p_offset INTEGER, p_order_by TEXT, p_order_type TEXT, p_start_date DATE, p_end_date DATE, p_company_ids TEXT DEFAULT NULL, p_address_ids TEXT DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
          SQL TEXT := '';
          rep_obj RECORD;
          rep_vendors JSON [];
          rep_vendor JSON;
          vendors_total INTEGER := 1;
        BEGIN
          IF p_limit > 0 THEN
            SQL = 'SELECT name, cuisine, (CASE WHEN ROUND(AVG( CASE WHEN rating > 0 THEN rating END), 2) IS NULL THEN 0.00 ELSE ROUND(AVG( CASE WHEN rating > 0 THEN rating END), 2) END) AS rating, SUM(total_spent) AS total_spent, SUM(number_of_meals) AS number_of_meals, ROUND(SUM(total_spent)/SUM(number_of_meals), 2) AS avg_cost_per_meal FROM (';
          ELSE
            SQL = 'SELECT CEIL(COUNT(*)::DECIMAL/5) AS total FROM (';
            SQL = SQL || 'SELECT name, cuisine, ROUND(AVG( CASE WHEN rating > 0 THEN rating END), 2) AS rating, SUM(total_spent) AS total_spent, SUM(number_of_meals) AS number_of_meals, ROUND(SUM(total_spent)/SUM(number_of_meals), 2) AS avg_cost_per_meal FROM (';
          END IF;
          SQL = SQL || 'SELECT name, string_agg(DISTINCT cuisine, '', '') AS cuisine, rating, total_spent, number_of_meals FROM rep_vendors WHERE dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          SQL = SQL || ' GROUP BY name, total_spent, rating, number_of_meals, dated_on, company_id, address_id) AS tbl GROUP BY name, cuisine';
          IF p_limit > 0 THEN
            SQL = SQL || ' ORDER BY '|| p_order_by ||' '|| p_order_type || ' LIMIT ' || p_limit || ' OFFSET ' || p_offset || '';
          ELSE
            SQL = SQL || ') AS tbl1';
          END IF;
          FOR rep_obj IN EXECUTE SQL
          LOOP
            IF p_limit > 0 THEN
              SELECT JSON_BUILD_OBJECT('name', rep_obj.name, 'cuisine', rep_obj.cuisine, 'rating', CASE WHEN rep_obj.rating IS NULL THEN 0.00 ELSE rep_obj.rating END, 'total_spent', rep_obj.total_spent, 'avg_cost_per_meal', rep_obj.avg_cost_per_meal, 'number_of_meals', rep_obj.number_of_meals) INTO rep_vendor;
              rep_vendors := array_append(rep_vendors, rep_vendor);
            ELSE
              vendors_total := rep_obj.total;
            END IF;
          END LOOP;
          -- Build the JSON Response:
          IF p_limit > 0 THEN
            RETURN (SELECT JSON_BUILD_OBJECT('vendors', rep_vendors, 'order_by', p_order_by, 'order_type', p_order_type));
          ELSE
            RETURN (SELECT JSON_BUILD_OBJECT('total', vendors_total));
          END IF;
        END $$
    LANGUAGE 'plpgsql';"
  end
  def self.down
    execute "DROP FUNCTION IF EXISTS rep_top_vendors(p_limit INTEGER, p_offset INTEGER, p_order_by TEXT, p_order_type TEXT, p_start_date DATE, p_end_date DATE, p_company_ids TEXT, p_address_ids TEXT);"
  end
end
