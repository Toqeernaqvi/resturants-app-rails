class PopulateTimeZoneToUsers < ActiveRecord::Migration[5.1]
  def change
    #User.where("time_zone IS NULL").update_all(time_zone: "Pacific Time (US & Canada)")
  end
end
