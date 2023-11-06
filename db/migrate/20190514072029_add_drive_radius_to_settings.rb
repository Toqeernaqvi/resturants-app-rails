class AddDriveRadiusToSettings < ActiveRecord::Migration[5.1]
  def change
  	add_column :settings, :drive_radius, :integer, default: 20
  end
end
