class AddBuffetAddonMarkupToCompanies < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :buffet_addons_markup, :decimal, precision: 8, scale: 4, default: 0
  end
end
