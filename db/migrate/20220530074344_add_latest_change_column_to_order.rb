class AddLatestChangeColumnToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :new_items_in_last24_hours, :integer, default: 0

  end
end
