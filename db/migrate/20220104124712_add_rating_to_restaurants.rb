class AddRatingToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :rating_total, :decimal, precision: 8, :scale => 2, default: "0.0"
    add_column :restaurants, :rating_count, :integer, default: 0
    add_column :restaurants, :average_rating, :decimal, precision: 8, :scale => 2, default: "0.0"
  end
end
