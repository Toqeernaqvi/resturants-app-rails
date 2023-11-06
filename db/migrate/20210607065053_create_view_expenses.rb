class CreateViewExpenses < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_expenses AS 
      SELECT orders.id, runningmenus.company_id, restaurants.name AS restaurant, companies.name AS company_name, companies.user_meal_budget AS company_budget, orders.quantity, orders.total_price, 
      ((companies.user_meal_budget * quantity) - total_price) AS savings, (runningmenus.delivery_at AT TIME ZONE 'PST') AS delivery_at, (orders.created_at AT TIME ZONE 'PST') AS created_at, (orders.updated_at AT TIME ZONE 'PST') AS updated_at
      FROM orders
      INNER JOIN runningmenus ON orders.runningmenu_id = runningmenus.id
      INNER JOIN companies ON runningmenus.company_id = companies.id
      INNER JOIN restaurants ON orders.restaurant_id = restaurants.id
      WHERE orders.status = 0 AND runningmenus.status = 0"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_expenses"
  end
end
