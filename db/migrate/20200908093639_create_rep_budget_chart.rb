class CreateRepBudgetChart < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION rep_budget_chart(p_start_date DATE, p_end_date DATE, p_group_by TEXT, p_company_ids TEXT DEFAULT NULL, p_address_ids TEXT DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
          SQL TEXT := '';
          total_budget DECIMAL := 0.0;
          rep_obj RECORD;
          budget_graph JSON;
          budget_analysis_graph JSON[];
        BEGIN
          -- Budget Analyses chart
          SQL = 'SELECT (SUM(food_cost)::DECIMAL) AS total FROM rep_budget_analyses WHERE dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          FOR rep_obj IN EXECUTE SQL
          LOOP
            IF rep_obj.total IS NOT NULL THEN
              total_budget := rep_obj.total::DECIMAL;
            END IF;
          END LOOP;
          SQL = 'SELECT department, ROUND(SUM(percentage), 2) AS percentage FROM (';
          SQL = SQL || 'SELECT ('|| p_group_by ||') AS department, (SUM(food_cost)::DECIMAL/(' || total_budget || ') * 100) AS percentage FROM rep_budget_analyses GROUP BY '|| p_group_by ||', company_id, address_id, dated_on HAVING dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          SQL = SQL || ') AS tbl GROUP BY tbl.department';
          FOR rep_obj IN EXECUTE SQL
          LOOP
            SELECT JSON_BUILD_OBJECT('id', rep_obj.department, 'label', rep_obj.department, 'value', rep_obj.percentage) INTO budget_graph;
            budget_analysis_graph := ARRAY_APPEND(budget_analysis_graph, budget_graph);
          END LOOP;
          -- Build the JSON Response:
          RETURN ( SELECT JSON_BUILD_OBJECT('budget_analysis_graph', COALESCE(budget_analysis_graph, ARRAY[]::json[]) ));
        END; $$
    LANGUAGE 'plpgsql';"
  end

  def self.down
    execute "DROP FUNCTION rep_budget_chart(p_start_date DATE, p_end_date DATE, p_group_by TEXT, p_company_ids TEXT, p_address_ids TEXT)"
  end
end
