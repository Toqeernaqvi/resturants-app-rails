class AddPreEmailToAddressRunningmenu < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses_runningmenus, :pre_email, :integer, default: 0
  end
end
