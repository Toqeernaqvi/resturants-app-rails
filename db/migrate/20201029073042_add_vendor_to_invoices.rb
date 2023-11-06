class AddVendorToInvoices < ActiveRecord::Migration[5.1]
  def change
    add_reference :invoices, :restaurant
    add_reference :invoices, :restaurant_address
    add_column :invoices, :delivery_type, :integer, default: 0
  end
end
