class CreateViewRepNutritions < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_rep_nutritions AS
    SELECT DISTINCT dietaries.name, dietaries.id AS dietary_id, users.company_id, users.address_id, dietaries_users.user_id
    FROM dietaries_users
    INNER JOIN dietaries ON dietaries.id = dietaries_users.dietary_id
    INNER JOIN users ON users.id = dietaries_users.user_id;"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_rep_nutritions;"
  end
end
