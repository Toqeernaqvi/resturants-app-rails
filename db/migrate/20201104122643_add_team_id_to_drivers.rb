class AddTeamIdToDrivers < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :onfleet_team_id, :string
    add_column :drivers, :onfleet_team_id, :string
  end
end
