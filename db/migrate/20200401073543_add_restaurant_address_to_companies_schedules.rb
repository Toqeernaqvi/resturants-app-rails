class AddRestaurantAddressToCompaniesSchedules < ActiveRecord::Migration[5.1]
  def change
    add_column :companies_schedules, :cuisineslist_id, :bigint
    add_column :companies_schedules, :restaurant_address_id, :bigint
  end
end
