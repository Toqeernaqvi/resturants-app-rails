class ImportVendors
  def call
    file_path = File.new(Rails.root.join('app/assets/csvs/vendors.csv'))
    spreadsheet = Roo::Spreadsheet.open(file_path)

    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]

      restaurant = Restaurant.create(
        name: row['Name'],
        vendor_id: row['VendorID'],
        migrated: true
      )

      address = restaurant.addresses.new(
        address_line: row['AddressString'],
        formatted_address: row['AddressString'],
        # street: row['street'],
        # city: row['city'],
        # state: row['state'],
        # zip: row['zip'],
        lunch_order_capacity: row['LunchOrderCapacity'],
        dinner_order_capacity: row['DinnerOrderCapacity'],
        notes: row['Remarks']
      )
      address.save(validate: false)
      if row['ConactName'].present? && (row['Mobile'].present? || row['Email'].present?)
        contact = address.contacts.new(
          name: row['ConactName'],
          phone_number: row['Mobile'],
          email: row['Email'],
          fax: row['FAX'],
        )
        contact.save
      end

      if row['ConactName'].present? && (row['Mobile2'].present? || row['Email2'].present?)
        contact1 = address.contacts.new(
          name: row['ConactName'],
          phone_number: row['Mobile2'],
          email: row['Email2'],
        )
        contact1.save
      end

      if row['ConactName'].present? && (row['Mobile3'].present? || row['Email3'].present?)
        contact2 = address.contacts.new(
          name: row['ConactName'],
          phone_number: row['Mobile3'],
          email: row['Email3'],
        )
        contact2.save
      end
    end
  end
end
