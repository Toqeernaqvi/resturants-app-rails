class UpdateApproveBanAddressCheck < ActiveRecord::Migration[5.1]
  def change
    runningmenus = Runningmenu.joins(:company => :ban_addresses).uniq
    runningmenus.each do |runningmenu|
      if runningmenu.company.ban_addresses.exists?(:address_id => runningmenu.address_ids) && runningmenu.approve_ban_restaurant == false
        runningmenu.update_column(:approve_ban_restaurant, true)
      end
    end
  end
end
