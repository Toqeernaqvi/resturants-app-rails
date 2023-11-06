class AddMarketplaceToCompanies < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :enable_marketplace, :boolean, default: :false
  end
end
