class AddAlertMailCheckToRestAddress < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :alert_email, :boolean, default: false, after: :buffet_price
  end
end
