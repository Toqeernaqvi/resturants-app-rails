class AddTimeZoneToRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :time_zone, :string
  end
end
