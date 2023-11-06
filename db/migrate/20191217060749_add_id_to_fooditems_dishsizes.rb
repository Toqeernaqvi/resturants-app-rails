class AddIdToFooditemsDishsizes < ActiveRecord::Migration[5.1]
  def change
    rename_table 'dishsizes_fooditems', 'dishsize_fooditems'
    add_column :dishsize_fooditems, :id, :primary_key
    add_column :dishsize_fooditems, :price, :decimal, precision: 8, scale: 4, default: 0
    remove_column :dishsizes, :price
  end
end
