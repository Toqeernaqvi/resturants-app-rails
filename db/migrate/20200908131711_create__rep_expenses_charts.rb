class CreateRepExpensesCharts < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION rep_expenses_charts(p_start_date DATE, p_end_date DATE, p_company_ids TEXT DEFAULT NULL, p_address_ids TEXT DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
          SQL TEXT := '';
          rep_obj RECORD;
          rep_chart JSON;
          rep_charts JSON[];
        BEGIN
          -- Expense and Saving charts
          SQL = 'SELECT SUM(expense) AS expense, SUM(saving) AS saving, SUM(meals) AS meals,
(CASE WHEN ((DATE_PART(''year'', ''' || p_end_date || '''::date) - DATE_PART(''year'', ''' || p_start_date || '''::date)) * 12 + (DATE_PART(''month'', ''' || p_end_date || '''::date) - DATE_PART(''month'', ''' || p_start_date || '''::date))) > 3 THEN TO_CHAR(dated_on,''YYYY mm'') WHEN ABS(''' || p_start_date || '''::DATE-''' || p_end_date || '''::DATE) < 30 THEN TO_CHAR(dated_on,''Mon dd, YYYY'') WHEN ABS(''' || p_start_date || '''::DATE-''' || p_end_date || '''::DATE) > 30 THEN ''Week ''::text || TO_CHAR(dated_on, ''IYYY-IW'') END) AS x FROM (';
          SQL = SQL || 'SELECT * FROM rep_charts WHERE dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          SQL = SQL || ') AS tbl GROUP BY 4 ORDER BY 4';
          FOR rep_obj IN EXECUTE SQL
          LOOP
            SELECT JSON_BUILD_OBJECT('expense', rep_obj.expense, 'saving', rep_obj.saving, 'meals', rep_obj.meals, 'x', rep_obj.x) INTO rep_chart;
            rep_charts := ARRAY_APPEND(rep_charts, rep_chart);
          END LOOP;
          -- Build the JSON Response:
          RETURN ( SELECT JSON_BUILD_OBJECT('rep_charts', COALESCE(rep_charts, ARRAY[]::json[]) ));
        END; $$
    LANGUAGE 'plpgsql';"
  end

  def self.down
    execute "DROP FUNCTION rep_expenses_charts(p_start_date DATE, p_end_date DATE, p_company_ids TEXT, p_address_ids TEXT)"
  end
end
