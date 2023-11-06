class AddFormattedGroupToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :formatted_group, :string
  end
end