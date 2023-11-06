class AddDistanceRadiusToSettings < ActiveRecord::Migration[5.1]
  def change
    add_column :settings, :distance_radius, :integer, default: 10
  end
end
