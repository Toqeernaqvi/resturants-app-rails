class AddInvoiceRelationToOrder < ActiveRecord::Migration[5.1]
  def change
    add_reference :orders, :invoice, index: true
  end
end
