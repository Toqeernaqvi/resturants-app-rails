class CreateViewAverageSavingsPerMeal < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_average_savings_per_meal AS 
      SELECT runningmenus.company_id, companies.name AS company_name, companies.user_meal_budget, orders.price, (companies.user_meal_budget - orders.price) AS savings_per_meal, (runningmenus.delivery_at AT TIME ZONE 'PST') AS delivery_at, (orders.created_at AT TIME ZONE 'PST') AS created_at, (orders.updated_at AT TIME ZONE 'PST') AS updated_at
      FROM orders
      INNER JOIN runningmenus ON orders.runningmenu_id = runningmenus.id
      INNER JOIN companies ON runningmenus.company_id = companies.id
      WHERE orders.status = 0 AND runningmenus.status = 0"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_average_savings_per_meal"
  end
end
