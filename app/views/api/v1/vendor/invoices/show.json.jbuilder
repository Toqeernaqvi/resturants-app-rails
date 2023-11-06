json.(
  @invoice, :id, :invoice_number, :status
)
json.restaurant_name @invoice.restaurant.name
json.bill_to @invoice.bill_to.html_safe
json.ship_to @invoice.ship_to.html_safe
json.delivery_date @invoice.ship_date_timezone
json.due_date @invoice.due_date_timezone
total_items = 0
json.line_items do
  line_items = []
  orders = @invoice.orders.active
  orders.group_by{|o| o.runningmenu.runningmenu_name }.each do |key, value|
    value.each do |order|
      total_items += order.quantity
      line_items << { id: order.id, item: order.fooditem.name, quantity: order.quantity, unit_price: number_with_precision(order.price, precision: 2), amount: number_with_precision((order.total_price - order.user_paid), precision: 2), discount: number_with_precision(order.discount, precision: 2), company_paid: number_with_precision(order.company_paid, precision: 2) }
    end
  end
  @invoice.line_items.each do |line_item|
    total_items += line_item.quantity
    line_items << { id: line_item.id, item: line_item.item, quantity: line_item.quantity, unit_price: number_with_precision(line_item.unit_price, precision: 2), amount: number_with_precision(line_item.amount, precision: 2), discount: number_with_precision(line_item.discount, precision: 2), company_paid: number_with_precision(line_item.amount, precision: 2) }
  end
  json.array! line_items.each do |line_item|
    json.id line_item[:id]
    json.item line_item[:item]
    json.quantity line_item[:quantity]
    json.unit_price number_with_precision(line_item[:unit_price], precision: 2)
    json.company_paid line_item[:company_paid]
    json.amount number_with_precision(line_item[:amount], precision: 2)
    json.discount number_with_precision(line_item[:discount], precision: 2)
  end
end
adjustments_total = 0
json.adjustments do
  json.array! @invoice.adjustments.each do |adjustment|
    adjustments_total = adjustment.addition? ? adjustments_total + adjustment.price : adjustments_total - adjustment.price
    json.id adjustment.id
    json.description adjustment.description
    json.adjustment_type adjustment.adjustment_type
    json.amount adjustment.price
  end
end
json.total_items total_items
json.sub_total @invoice.total_amount_due-adjustments_total
json.adjustments_total adjustments_total
json.sale_tax_percentage "#{@invoice.sale_tax_percentage*100}%"
sales_tax = @invoice.amount_due_without_fee*@invoice.sale_tax_percentage
json.sales_tax sales_tax
json.total_due @invoice.total_amount_due+sales_tax