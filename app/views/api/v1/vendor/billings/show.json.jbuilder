json.billing do
  json.id @billing.id
  json.billing_number @billing.billing_number
  json.orders_from @billing.orders_from
  json.orders_to @billing.orders_to
  json.total_items @billing.quantity_total
  json.food_total @billing.food_total
  json.commission @billing.commission
  json.commission_percentage @billing.discount_percentage
  json.sales_tax @billing.sales_tax
  json.sales_tax_percentage (sprintf "%.2f", @billing.sale_tax_percentage*100)
  json.payment_status @billing.payment_status


  json.orders @orders
  json.adjustments @billing.adjustments
  json.total_payout @billing.payout_total
end
