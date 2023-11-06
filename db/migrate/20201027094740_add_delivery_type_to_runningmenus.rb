class AddDeliveryTypeToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :delivery_type, :integer, default: 0
  end
end
