class AddParentCompanyToCompanies < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :parent_company_id, :integer
  end
end
