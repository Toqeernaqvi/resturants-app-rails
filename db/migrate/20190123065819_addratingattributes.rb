class Addratingattributes < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :rating, :decimal, precision: 3, scale: 2, default: "0.0", after: :status

    add_column :fooditems, :rating_total, :decimal, precision: 3, scale: 2, default: "0.0"
    add_column :fooditems, :rating_count, :integer, default: 0
    add_column :fooditems, :average_rating, :decimal, precision: 3, scale: 2, default: "0.0"
  end
end
