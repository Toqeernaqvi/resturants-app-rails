class AddDynamicSectionToAddressesRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_reference :addresses_runningmenus, :dynamic_section, foreign_key: true
  end
end
