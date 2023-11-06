class SetTimeZoneOfAddresses < ActiveRecord::Migration[5.1]
  def change
  	#Address.where("time_zone IS NULL").update_all(time_zone: "Pacific Time (US & Canada)")
  end
end
