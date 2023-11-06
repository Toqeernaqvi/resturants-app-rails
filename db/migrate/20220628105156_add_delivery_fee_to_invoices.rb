class AddDeliveryFeeToInvoices < ActiveRecord::Migration[5.1]
  def change
    add_column :invoices, :delivery_fee_total, :decimal, precision: 8, scale: 2, default: 0.00
  end
end
