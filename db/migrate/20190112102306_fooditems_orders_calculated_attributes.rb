class FooditemsOrdersCalculatedAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :fooditems, :gross_price, :decimal, default: 0, :precision => 8, :scale => 2, after: :price
  end
end
