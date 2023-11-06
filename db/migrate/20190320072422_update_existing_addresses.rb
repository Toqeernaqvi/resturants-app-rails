class UpdateExistingAddresses < ActiveRecord::Migration[5.1]
  def change
    Address.all.each do |address|
      concat_address = [ address.street, address.city, address.state, address.zip].compact.join(', ')
      g = Geocoder.search(concat_address)
      if g.present?
        data = g.first
        address.address_line = data.address
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
