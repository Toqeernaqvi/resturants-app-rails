class AddRatingColumns < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :rating_total, :decimal, precision: 8, :scale => 2, default: "0.0"
    add_column :addresses, :rating_count, :integer, default: 0
    add_column :addresses, :average_rating, :decimal, precision: 8, :scale => 2, default: "0.0"

    add_column :runningmenus, :rating_total, :decimal, precision: 8, :scale => 2, default: "0.0"
    add_column :runningmenus, :rating_count, :integer, default: 0
    add_column :runningmenus, :average_rating, :decimal, precision: 8, :scale => 2, default: "0.0"
  end
end
