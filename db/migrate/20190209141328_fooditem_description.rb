class FooditemDescription < ActiveRecord::Migration[5.1]
  def change
    change_column :gfooditems, :description, :text, :limit => 1024
    change_column :fooditems, :description, :text, :limit => 1024
  end
end
