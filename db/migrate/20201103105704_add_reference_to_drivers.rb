class AddReferenceToDrivers < ActiveRecord::Migration[5.1]
  def change
    add_column :drivers, :restaurant_address_id, :bigint
    add_index :drivers, :restaurant_address_id
  end
end
