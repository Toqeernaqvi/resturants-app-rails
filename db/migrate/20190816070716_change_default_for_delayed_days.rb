class ChangeDefaultForDelayedDays < ActiveRecord::Migration[5.1]
  def up
    change_column :addresses, :delayed_payout_days, :integer, default: 6
  end
  
  def down
    change_column :addresses, :delayed_payout_days, :integer, default: 0
  end
end
