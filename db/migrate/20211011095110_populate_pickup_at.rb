class PopulatePickupAt < ActiveRecord::Migration[5.1]
  def change
    Runningmenu.all.each do |r|
      r.update_column(:pickup_at, r.delivery_at-1.hour-15.minutes)
    end
  end
end
