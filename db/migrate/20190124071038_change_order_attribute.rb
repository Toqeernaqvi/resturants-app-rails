class ChangeOrderAttribute < ActiveRecord::Migration[5.1]
  def change
    change_column :fooditems, :rating_total, :decimal, precision: 15, scale: 2, default: "0.0"
  end
end
