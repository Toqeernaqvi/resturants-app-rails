class CompaniesAddressShortcode < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :short_code, :string, after: :address_line
    remove_column :companies, :short_code, :string, after: :name
  end
end
