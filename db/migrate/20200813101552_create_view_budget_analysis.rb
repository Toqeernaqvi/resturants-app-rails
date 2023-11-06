class CreateViewBudgetAnalysis < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_rep_budget_analysis AS
    SELECT companies.id AS company_id, addresses.id AS address_id, companies.name AS company_name, CONCAT(addresses.street_number, ' ', addresses.street) AS company_address, SUM(orders.number_of_meals) AS quantity, SUM(orders.total_price) AS food_cost, NULL AS service_cost_avg, companies.user_meal_budget AS budget, DATE(runningmenus.delivery_at AT TIME ZONE 'US/PACIFIC') AS dated_on
    FROM runningmenus
    INNER JOIN companies ON companies.id = runningmenus.company_id
    INNER JOIN addresses ON addresses.id = runningmenus.address_id
    INNER JOIN orders ON orders.runningmenu_id = runningmenus.id AND orders.status = 0 AND runningmenus.status = 0 AND orders.number_of_meals > 0
    GROUP BY companies.id, addresses.id, dated_on HAVING DATE(runningmenus.delivery_at AT TIME ZONE 'US/PACIFIC') < CURRENT_DATE AT TIME ZONE 'US/PACIFIC';"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_rep_budget_analysis"
  end
end
