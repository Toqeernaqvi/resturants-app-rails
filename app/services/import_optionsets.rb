class ImportOptionsets
  def call
    file_path = File.new(Rails.root.join('app/assets/csvs/options_master.csv'))
    spreadsheet = Roo::Spreadsheet.open(file_path)

    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      restaurant = Restaurant.find_by(vendor_id: row['VendorID'])
      if restaurant.present?
        gmenu = restaurant.gmenus.first
        gmenu.goptionsets.create(
          choice_type: row['ID'],
          name: row['Name'],
          required: row['IsMandatory'],
          end_limit: row['MaxCount']
        )
      end
    end
  end
end
