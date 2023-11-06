class AddTimeZoneValuesToCompanyRestaurants < ActiveRecord::Migration[5.1]
  def change
    Company.where("time_zone IS NULL").update_all(time_zone: "Pacific Time (US & Canada)")
    Restaurant.where("time_zone IS NULL").update_all(time_zone: "Pacific Time (US & Canada)")
  end
end
