class RemoveCompanyPackageFromCompanies < ActiveRecord::Migration[5.1]
  def change
    remove_column :companies, :company_package, :boolean
  end
end
