class EnableSaasToCompanies < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :enable_saas, :boolean, default: false
  end
end
