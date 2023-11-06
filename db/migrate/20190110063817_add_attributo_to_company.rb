class AddAttributoToCompany < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :user_copay, :integer, default: 0
    add_column :companies, :copay_amount, :integer, default: 0
  end
end
