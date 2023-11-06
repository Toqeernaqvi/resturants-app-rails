class AddPayoutFieldsToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :delayed_payout_days, :integer, default: 0
    add_column :addresses, :discount_percentage, :decimal, default: 0, :precision => 8, :scale => 2
  end
end
