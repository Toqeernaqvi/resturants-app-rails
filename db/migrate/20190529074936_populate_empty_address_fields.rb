class PopulateEmptyAddressFields < ActiveRecord::Migration[5.1]
  def change
    Address.active.where('street_number IS NUll OR street_number = ?', '').each do |address|
      g = Geocoder.search(address.address_line)
      if g.present?
        data = g.first
        address.latitude = data.latitude
        address.longitude = data.longitude
        address.street_number = data.house_number
        address.street = data.street
        address.city = data.city
        address.state = data.state
        address.zip = data.postal_code
      end
      address.save
    end
  end
end
