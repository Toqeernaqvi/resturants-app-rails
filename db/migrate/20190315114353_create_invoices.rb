class CreateInvoices < ActiveRecord::Migration[5.1]
  # def self.up
  #   create_table :invoices do |t|
  #     t.integer :invoice_number
  #     t.text :bill_to
  #     t.text :ship_to
  #     t.text :payment_terms
  #     t.datetime :ship_date
  #     t.datetime :due_date
  #     t.integer :status

  #     t.timestamps
  #   end
  #   execute "CREATE SEQUENCE invoices_invoice_number_seq OWNED BY invoices.invoice_number INCREMENT BY 1 START WITH 1001"
  # end

  # def self.down
  #   drop_table :invoices
  #   execute "DELETE SEQUENCE invoices_invoice_number_seq"
  # end
  def change
    create_table :invoices do |t|
      t.integer :invoice_number
      t.text :bill_to
      t.text :ship_to
      t.text :payment_terms
      t.datetime :ship_date
      t.datetime :due_date
      t.integer :status

      t.timestamps
    end
  end
end
