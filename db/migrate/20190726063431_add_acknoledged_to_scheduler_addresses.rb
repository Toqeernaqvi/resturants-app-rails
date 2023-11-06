class AddAcknoledgedToSchedulerAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses_runningmenus, :acknowledge_receipt, :integer, default: 0
    add_column :addresses_runningmenus, :accept_orders, :integer, default: 0
    add_column :addresses_runningmenus, :accept_changes, :integer, default: 0
  end
end
