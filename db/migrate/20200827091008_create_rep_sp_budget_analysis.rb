class CreateRepSpBudgetAnalysis < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION rep_budget_analyses(p_limit INTEGER, p_offset INTEGER, p_order_by TEXT, p_order_type TEXT, p_group_by TEXT, p_start_date DATE, p_end_date DATE, p_company_ids TEXT DEFAULT NULL, p_address_ids TEXT DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
          SQL TEXT;
          rep_obj RECORD;
          budget_obj JSON;
          budget_analysis JSON[];
          budget_analysis_total INTEGER := 0;
        BEGIN
          IF p_limit > 0 THEN
            SQL = 'SELECT '|| p_group_by ||', budget, SUM(quantity) AS quantity, SUM(food_cost) AS food_cost, ROUND(SUM(food_cost)/SUM(quantity), 2) AS food_cost_avg, ROUND(AVG(service_cost_avg), 2) AS service_cost_avg, (budget-ROUND(SUM(food_cost)/SUM(quantity), 2))*SUM(quantity) AS savings FROM (';
          ELSE
            SQL = 'SELECT CEIL(COUNT(*)::DECIMAL/5) AS total FROM (';
            SQL = SQL || 'SELECT '|| p_group_by ||', budget, SUM(quantity) AS quantity, SUM(food_cost) AS food_cost, ROUND(SUM(food_cost)/SUM(quantity), 2) AS food_cost_avg, ROUND(AVG(service_cost_avg), 1) AS service_cost_avg, (budget-ROUND(SUM(food_cost)/SUM(quantity), 2))*SUM(quantity) AS savings FROM (';
          END IF;
          SQL = SQL || 'SELECT * FROM rep_budget_analyses WHERE dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          SQL = SQL || ') AS tbl GROUP BY '|| p_group_by ||', budget';
          IF p_limit > 0 THEN
            SQL = SQL || ' ORDER BY '|| p_order_by ||' '|| p_order_type ||' LIMIT '|| p_limit ||' OFFSET '|| p_offset ||' ';
          ELSE
            SQL = SQL || ') AS tbl1';
          END IF;
          FOR rep_obj IN EXECUTE SQL
          LOOP
            IF p_limit > 0 THEN
              IF p_group_by = 'company_name' THEN
                SELECT JSON_BUILD_OBJECT('department', rep_obj.company_name, 'quantity', rep_obj.quantity, 'food_cost', rep_obj.food_cost, 'food_cost_avg', rep_obj.food_cost_avg, 'service_cost_avg', rep_obj.service_cost_avg, 'budget', rep_obj.budget, 'savings', rep_obj.savings) INTO budget_obj;
              ELSE
                SELECT JSON_BUILD_OBJECT('department', rep_obj.company_address, 'quantity', rep_obj.quantity, 'food_cost', rep_obj.food_cost, 'food_cost_avg', rep_obj.food_cost_avg, 'service_cost_avg', rep_obj.service_cost_avg, 'budget', rep_obj.budget, 'savings', rep_obj.savings) INTO budget_obj;
              END IF;
              budget_analysis := ARRAY_APPEND(budget_analysis, budget_obj);
            ELSE
              budget_analysis_total := rep_obj.total::INT;
            END IF;
          END LOOP;
          IF p_limit > 0 THEN
            IF p_order_by = 'company_name' OR p_order_by = 'company_address' THEN
              p_order_by = 'department';
            END IF;
            RETURN (SELECT JSON_BUILD_OBJECT('budget_analysis', budget_analysis, 'order_by', p_order_by, 'order_type', p_order_type));
          ELSE
            RETURN (SELECT JSON_BUILD_OBJECT('total', budget_analysis_total));
          END IF;
        END $$
    LANGUAGE 'plpgsql';"
  end

  def self.down
    execute "DROP FUNCTION IF EXISTS rep_budget_analyses(p_limit INTEGER, p_offset INTEGER, p_order_by TEXT, p_order_type TEXT, p_group_by TEXT, p_start_date DATE, p_end_date DATE, p_company_ids TEXT, p_address_ids TEXT)"
  end
end
