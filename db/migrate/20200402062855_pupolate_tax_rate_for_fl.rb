class PupolateTaxRateForFl < ActiveRecord::Migration[5.1]
  def change
    require 'csv'

    csv_text = File.read(Rails.root.join('app/assets/csvs/TAXRATES_ZIP5_FL202003.csv'))
    csv = CSV.parse(csv_text, :headers => true)

    csv.each do |row|
      TaxRate.create!(row.to_hash)
    end

  end
end
