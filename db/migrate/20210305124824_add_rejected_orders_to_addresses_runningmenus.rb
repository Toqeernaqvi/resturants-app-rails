class AddRejectedOrdersToAddressesRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses_runningmenus, :rejected_by_vendor, :boolean, default: false
    add_column :addresses_runningmenus, :reject_reason, :text
  end
end
