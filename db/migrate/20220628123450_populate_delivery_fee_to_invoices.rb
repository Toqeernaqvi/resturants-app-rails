class PopulateDeliveryFeeToInvoices < ActiveRecord::Migration[5.1]
  def change
    Invoice.joins(:line_items).uniq.each do |invoice|
      invoice.update_column(:delivery_fee_total, invoice.line_items.where("item ILIKE '%delivery%'").sum(:amount))
    end
  end
end
