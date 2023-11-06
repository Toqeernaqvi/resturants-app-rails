class AddOrderDeleteTimeToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :cancelled_time, :datetime, after: :ordered_at
  end
end
