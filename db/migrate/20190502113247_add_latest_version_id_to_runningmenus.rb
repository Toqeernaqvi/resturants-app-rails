class AddLatestVersionIdToRunningmenus < ActiveRecord::Migration[5.1]
  def change
  	add_column :runningmenus, :latest_version_id, :bigint
  end
end
