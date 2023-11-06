class AddStatusToRatings < ActiveRecord::Migration[5.1]
  def change
    add_column :ratings, :status, :integer, default: 0
    add_column :ratings, :parent_status, :integer, default: 0
  end
end
