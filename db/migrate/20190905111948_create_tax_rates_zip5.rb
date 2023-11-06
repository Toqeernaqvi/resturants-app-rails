class CreateTaxRatesZip5 < ActiveRecord::Migration[5.1]
  def change
    create_table :tax_rates_zip5s do |t|
      t.string :state
      t.string :zip
      t.string :tax_region_name
      t.decimal :state_rate, precision: 8, scale: 4
      t.decimal :estimated_combined_rate, precision: 8, scale: 4
      t.decimal :estimated_county_rate, precision: 8, scale: 4
      t.decimal :estimated_city_rate, precision: 8, scale: 4
      t.decimal :estimated_special_rate, precision: 8, scale: 4
      t.integer :risk_level, default: 0
    end
  end
end
