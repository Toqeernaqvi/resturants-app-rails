class RemoveBillingAttributes < ActiveRecord::Migration[5.1]
  def change
    remove_column :billings, :cvc, :integer
    remove_column :billings, :expiry_year, :string
    remove_column :billings, :expiry_month, :string
    remove_column :billings, :card_number, :string
    add_column :billings, :token, :string
  end
end
