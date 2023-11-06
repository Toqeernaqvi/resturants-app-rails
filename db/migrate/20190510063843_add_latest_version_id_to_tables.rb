class AddLatestVersionIdToTables < ActiveRecord::Migration[5.1]
  def change
  	add_column :cuisines_menus, :latest_version_id, :bigint
  	add_column :runningmenufields, :latest_version_id, :bigint
  end
end
