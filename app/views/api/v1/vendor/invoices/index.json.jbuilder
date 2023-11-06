json.invoices_total @invoices_total
json.per_page @per_page
json.invoice @invoices.each do |invoice|
  json.(
    invoice, :id, :total_amount, :total_amount_due, :status
  )
  sales_tax = invoice.amount_due_without_fee * invoice.sale_tax_percentage
  json.total_amount_due (sprintf "%.2f",(invoice.total_amount_due + sales_tax)).to_f
  json.company_name invoice.company.name
  json.delivery_fee invoice.line_items.where("item ILIKE '%delivery%'").sum(:amount)
  json.adjustments invoice.adjustments.addition.sum(:price) - invoice.adjustments.discount.sum(:price)
end