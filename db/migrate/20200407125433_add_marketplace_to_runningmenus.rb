class AddMarketplaceToRunningmenus < ActiveRecord::Migration[5.1]
  def change
  	add_column :runningmenus, :marketplace, :boolean, default: false
  end
end
