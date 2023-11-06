class AddTokenToAddressesRunningmenu < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses_runningmenus, :token, :string
  end
end
