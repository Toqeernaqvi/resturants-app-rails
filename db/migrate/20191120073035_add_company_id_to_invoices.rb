class AddCompanyIdToInvoices < ActiveRecord::Migration[5.1]
  def self.up
    add_reference :invoices, :company, index: true

    Invoice.where(company_id: nil).each do |invoice|
      company_id = invoice.orders.active.last&.runningmenu&.company_id
      invoice.update_column(:company_id, company_id) unless company_id.blank?
    end
  end

  def self.down
    remove_reference :invoices, :company, index: true
  end
end
