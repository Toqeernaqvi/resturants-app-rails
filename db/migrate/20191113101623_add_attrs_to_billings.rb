class AddAttrsToBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :billings, :delivery_fee, :decimal, :precision => 8, :scale => 2, default: 0
    add_column :billings, :disable_auto_invoice, :boolean, default: false
    add_column :invoices, :delivery_fee, :decimal, :precision => 8, :scale => 2, default: 0
    add_column :invoices, :from, :datetime
    add_column :invoices, :to, :datetime
  end
end
