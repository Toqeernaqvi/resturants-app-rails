class CreateViewRepSatisfactions < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_rep_satisfactions AS
    SELECT dietaries.name, dietaries.id AS dietary_id, runningmenus.company_id, runningmenus.address_id, DATE(runningmenus.delivery_at AT TIME ZONE 'US/PACIFIC') AS dated_on
    FROM runningmenus 
    INNER JOIN orders ON orders.runningmenu_id = runningmenus.id
    INNER JOIN dietaries_fooditems ON dietaries_fooditems.fooditem_id = orders.fooditem_id
    INNER JOIN dietaries ON dietaries.id = dietaries_fooditems.dietary_id
    WHERE DATE(runningmenus.delivery_at) < CURRENT_DATE;"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_rep_satisfactions"
  end
end
