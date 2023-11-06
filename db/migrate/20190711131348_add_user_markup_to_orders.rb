class AddUserMarkupToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :user_markup, :boolean, default: false
  end
end
