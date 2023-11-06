class Addprefervendortorestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :preferred_vendor, :boolean, default: false
  end
end
