class AddServiceFeeToInvoices < ActiveRecord::Migration[5.1]
  def change
    add_column :invoices, :service_fee, :decimal, default: 0, :precision => 8, :scale => 2
  end
end
