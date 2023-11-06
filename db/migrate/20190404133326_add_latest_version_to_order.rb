class AddLatestVersionToOrder < ActiveRecord::Migration[5.1]
  def change
  	add_column :orders, :latest_version_id, :bigint
  end
end
