class CreateSpRepSatisfaction < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION sp_rep_satisfaction(p_start_date DATE, p_end_date DATE, p_dietary_ids TEXT, p_company_ids TEXT DEFAULT NULL, p_address_ids TEXT DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
          SQL TEXT := '';
          rep_satisfaction JSON;
          rep_satisfactions JSON[];
          rep_obj RECORD;
        BEGIN
          SQL = 'SELECT name, COUNT(name) AS total FROM (';
          SQL = SQL || 'SELECT * FROM rep_satisfactions WHERE dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          IF p_dietary_ids IS NOT NULL THEN
            SQL = SQL || ' AND dietary_id IN(' || p_dietary_ids || ')';
          END IF;
          SQL = SQL || ') AS tbl GROUP BY tbl.name';
          FOR rep_obj IN EXECUTE SQL
          LOOP
            SELECT JSON_BUILD_OBJECT('name', rep_obj.name, 'total', rep_obj.total) INTO rep_satisfaction;
            rep_satisfactions := ARRAY_APPEND(rep_satisfactions, rep_satisfaction);
          END LOOP;

          -- Build the JSON Response:
          RETURN (SELECT JSON_BUILD_OBJECT(
              'satisfactions', COALESCE(rep_satisfactions, ARRAY[]::json[])
            )
          );
        END; $$
    LANGUAGE 'plpgsql';"
  end

  def self.down
    execute "DROP FUNCTION sp_rep_satisfaction(p_start_date DATE, p_end_date DATE, p_dietary_ids TEXT, p_company_ids TEXT, p_address_ids TEXT)"
  end
end
