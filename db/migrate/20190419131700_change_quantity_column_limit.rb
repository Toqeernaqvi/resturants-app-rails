class ChangeQuantityColumnLimit < ActiveRecord::Migration[5.1]
  def up
    change_column :orders, :quantity, :integer, :limit => 5
  end

  def down
    change_column :orders, :quantity, :integer, :limit => 4
  end
end
