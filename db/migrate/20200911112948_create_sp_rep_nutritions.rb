class CreateSpRepNutritions < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION sp_rep_nutritions(p_limit INTEGER, p_offset INTEGER, p_order_by TEXT, p_order_type TEXT, p_start_date DATE, p_end_date DATE, p_company_ids TEXT DEFAULT NULL, p_address_ids TEXT DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
          SQL TEXT := '';
          rep_obj RECORD;
          total_users DECIMAL := 0.0;
          rep_nutritions JSON [];
          rep_nutrition JSON;
          nutritions_total INTEGER := 1;
        BEGIN
          SQL = 'SELECT (COUNT(*)::DECIMAL) AS total FROM users WHERE status = 0';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          FOR rep_obj IN EXECUTE SQL
          LOOP
            IF rep_obj.total IS NOT NULL THEN
              total_users := rep_obj.total::DECIMAL;
            END IF;
          END LOOP;

          IF p_limit > 0 THEN
            SQL = 'SELECT name, dietary_id, COUNT(DISTINCT user_id) AS users, ROUND(((COUNT(DISTINCT user_id)::DECIMAL/' || total_users || ')*100), 2) AS percentage_users FROM (';
          ELSE
            SQL = 'SELECT CEIL(COUNT(*)::DECIMAL/5) AS total FROM (';
            SQL = SQL || 'SELECT name, dietary_id, COUNT(DISTINCT user_id) AS users, ROUND(((COUNT(DISTINCT user_id)::DECIMAL/' || total_users || ')*100), 2) AS percentage_users FROM (';
          END IF;
          SQL = SQL || 'SELECT * FROM rep_nutritions WHERE 1=1';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          SQL = SQL || ') AS tbl GROUP BY name, dietary_id';
          IF p_limit > 0 THEN
            -- SQL = SQL || ' ORDER BY '|| p_order_by ||' '|| p_order_type || ' LIMIT ' || p_limit || ' OFFSET ' || p_offset || '';
            SQL = SQL || ' ORDER BY '|| p_order_by ||' '|| p_order_type || '';
          ELSE
            SQL = SQL || ') AS tbl1';
          END IF;
          FOR rep_obj IN EXECUTE SQL
          LOOP
            IF p_limit > 0 THEN
              SELECT JSON_BUILD_OBJECT('dietary_id', rep_obj.dietary_id, 'name', rep_obj.name, 'users', rep_obj.users, 'percentage_users', rep_obj.percentage_users) INTO rep_nutrition;
              rep_nutritions := array_append(rep_nutritions, rep_nutrition);
            ELSE
              nutritions_total := rep_obj.total;
            END IF;
          END LOOP;
          -- Build the JSON Response:
          IF p_limit > 0 THEN
            RETURN (SELECT JSON_BUILD_OBJECT('nutritions', rep_nutritions, 'order_by', p_order_by, 'order_type', p_order_type));
          ELSE
            RETURN (SELECT JSON_BUILD_OBJECT('total', nutritions_total));
          END IF;
        END $$
    LANGUAGE 'plpgsql';"
  end
  def self.down
    execute "DROP FUNCTION IF EXISTS sp_rep_nutritions(p_limit INTEGER, p_offset INTEGER, p_order_by TEXT, p_order_type TEXT, p_start_date DATE, p_end_date DATE, p_company_ids TEXT, p_address_ids TEXT);"
  end
end
