class AddGroupToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :group, :string
  end
end
