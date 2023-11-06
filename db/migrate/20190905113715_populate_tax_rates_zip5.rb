class PopulateTaxRatesZip5 < ActiveRecord::Migration[5.1]
  def change
    require 'csv'

    csv_text = File.read(Rails.root.join('app/assets/csvs/TAXRATES_ZIP5_CA201909.csv'))
    csv = CSV.parse(csv_text, :headers => true)

    csv.each do |row|
      TaxRate.create!(row.to_hash)
    end

  end
end
