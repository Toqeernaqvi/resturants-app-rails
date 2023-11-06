json.count @count
json.per_page @per_page
json.billings @billings do |billing|
  json.id billing.id
  json.billing_number billing.billing_number
  json.billing_type billing.billing_type
  json.quantity_total billing.quantity_total
  json.orders_from billing.orders_from
  json.orders_to billing.orders_to
  json.food_total billing.food_total
  json.commission billing.commission
  json.commission_percentage (sprintf "%.2f",(billing.commission/billing.food_total)*100).to_f
  json.payout_total billing.payout_total
  json.payment_status billing.payment_status
  json.due_date billing.due_date
end
