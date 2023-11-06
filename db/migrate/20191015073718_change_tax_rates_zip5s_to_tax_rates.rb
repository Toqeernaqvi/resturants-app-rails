class ChangeTaxRatesZip5sToTaxRates < ActiveRecord::Migration[5.1]
  def change
    rename_table :tax_rates_zip5s, :tax_rates
  end
end
