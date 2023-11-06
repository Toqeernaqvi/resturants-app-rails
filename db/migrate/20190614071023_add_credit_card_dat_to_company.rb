class AddCreditCardDatToCompany < ActiveRecord::Migration[5.1]
  def change
    add_column :billings, :card_number, :string, after: :invoice_credit_card
    add_column :billings, :expiry_month, :string, after: :invoice_credit_card
    add_column :billings, :expiry_year, :string, after: :invoice_credit_card
    add_column :billings, :cvc, :integer, after: :invoice_credit_card
    add_column :billings, :customer_id, :string, after: :invoice_credit_card
  end
end
