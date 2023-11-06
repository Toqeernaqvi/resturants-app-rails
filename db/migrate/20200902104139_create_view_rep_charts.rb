class CreateViewRepCharts < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_rep_charts AS
      SELECT runningmenus.company_id, runningmenus.address_id, 
      SUM(orders.total_price) AS expense, SUM(runningmenus.per_meal_budget*orders.number_of_meals-orders.total_price) AS saving, SUM(orders.number_of_meals) AS meals, DATE(runningmenus.delivery_at AT TIME ZONE 'US/PACIFIC') AS dated_on
      FROM runningmenus
      INNER JOIN orders ON orders.runningmenu_id = runningmenus.id AND orders.status = 0 AND runningmenus.status = 0
      GROUP BY runningmenus.company_id, runningmenus.address_id, dated_on;"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_rep_charts;"
  end
end
