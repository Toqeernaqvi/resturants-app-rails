class SavePreviousRestaurantAdminAddresses < ActiveRecord::Migration[5.1]
  def change
    results = RestaurantAdmin.pluck(:id, :address_id)
    results.each do |result|
      AddressesVendor.create(user_id: result[0], address_id: result[1])
    end
  end
end
