class CreateReportsStoredProcedure < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION reports(p_start_date DATE, p_end_date DATE, p_group_by TEXT DEFAULT NULL, p_company_ids TEXT DEFAULT NULL, p_address_ids TEXT DEFAULT NULL)
      RETURNS JSON
        AS $$
        DECLARE
          SQL TEXT := '';
          rep_box JSON;
          budget_analysis_total JSON;
          rep_obj RECORD;
          vendors_total_pages JSON;
          nutritions_total_pages JSON;
          cuisines_total INTEGER := 0;
        BEGIN
          -- Top boxes data object
          SQL = 'SELECT COUNT(DISTINCT cuisine) AS total FROM (';
          SQL = SQL || 'SELECT UNNEST(cuisines) AS cuisine FROM rep_boxes WHERE dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          SQL = SQL || ') AS tbl';
          FOR rep_obj IN EXECUTE SQL
          LOOP
            cuisines_total := rep_obj.total;
          END LOOP;
          SQL = 'SELECT ROUND(AVG(CASE WHEN average_food_rating > 0 THEN average_food_rating END)::NUMERIC, 1) AS average_food_rating, ROUND(AVG(CASE WHEN average_service_rating > 0 THEN average_service_rating END)::NUMERIC, 1) AS average_service_rating, ROUND(AVG(on_time_deliveries)::NUMERIC, 1) AS on_time_deliveries, SUM(meals) AS meals, COUNT(DISTINCT vendors) AS vendors FROM rep_boxes WHERE dated_on >= ''' || p_start_date || ''' AND dated_on <= ''' || p_end_date || '''';
          IF p_company_ids IS NOT NULL THEN
            SQL = SQL || ' AND company_id IN(' || p_company_ids || ')';
          END IF;
          IF p_address_ids IS NOT NULL THEN
            SQL = SQL || ' AND address_id IN(' || p_address_ids || ')';
          END IF;
          FOR rep_obj IN EXECUTE SQL
          LOOP
            SELECT JSON_BUILD_OBJECT('average_food_rating', rep_obj.average_food_rating, 'average_service_rating', rep_obj.average_service_rating, 'on_time_deliveries', rep_obj.on_time_deliveries, 'meals', rep_obj.meals, 'vendors', rep_obj.vendors, 'cuisines', cuisines_total) INTO rep_box;
          END LOOP;

          vendors_total_pages := rep_top_vendors(0, 0, 'rating', 'DESC', p_start_date, p_end_date, p_company_ids, p_address_ids);
          budget_analysis_total := rep_budget_analyses(0, 0, 'quantity', 'DESC', p_group_by, p_start_date, p_end_date, p_company_ids, p_address_ids);
          nutritions_total_pages := sp_rep_nutritions(0, 0, 'name', 'DESC', p_start_date, p_end_date, p_company_ids, p_address_ids);

          -- Build the JSON Response:
          RETURN (SELECT JSON_BUILD_OBJECT(
              'rep_box', rep_box,
              'vendors_total_pages', vendors_total_pages->'total',
              'budget_analysis_total_pages', budget_analysis_total->'total',
              'nutritions_total_pages', nutritions_total_pages->'total'
            )
          );
        END; $$
    LANGUAGE 'plpgsql';"
  end

  def self.down
    execute "DROP FUNCTION reports(p_start_date DATE, p_end_date DATE, p_group_by TEXT, p_company_ids TEXT, p_address_ids TEXT)"
  end
end
