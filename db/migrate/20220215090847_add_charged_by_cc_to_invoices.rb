class AddChargedByCcToInvoices < ActiveRecord::Migration[5.1]
  def change
    add_column :invoices, :charged_cc, :boolean, default: false
    add_column :invoices, :paid_date, :datetime
  end
end
