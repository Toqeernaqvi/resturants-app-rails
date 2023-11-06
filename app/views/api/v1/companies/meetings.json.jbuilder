json.from @from
json.to @to
json.total_meetings_count @meetings_count
json.set! 'meetings' do
  json.array! @meetings do |meeting|
    json.runningmenu_id meeting.id
    json.slug meeting.slug
    json.runningmenu_name meeting.runningmenu_name
    rest_name = meeting.orders.joins(:restaurant).select("STRING_AGG(DISTINCT restaurants.name, ', ') AS r_names").group('orders.id')
    json.restaurant_name rest_name.first.r_names
    json.formatted_address meeting.address.formatted_address
    json.meeting_type meeting.runningmenu_type
    json.delivery_at meeting.delivery_at_timezone
    if current_member.company_user? || current_member.unsubsidized_user? || current_member.company_manager?
      json.total_orders meeting.orders.active.where(user_id: current_member.id).sum(:quantity).to_i
      total_paid = meeting.orders.active.where(user_id: current_member.id).pluck("ROUND(SUM(CASE WHEN orders.user_paid > 0 THEN (CASE WHEN (orders.user_paid+0.30)/(1-0.029) > 0.50 THEN (orders.user_paid+0.30)/(1-0.029) ELSE 0.50 END) ELSE orders.user_paid END), 2) AS total_user_paid").last
      json.order_total total_paid > 0 ? total_paid : 0
    else
      json.total_orders meeting.orders.active.sum(:quantity).to_i
      user_paid_total = meeting.orders.active.sum(:user_paid)
      json.order_total meeting.orders.active.sum(:total_price) - user_paid_total
    end
    invoice = meeting.orders.active.last&.invoice
    if invoice.present?
      json.delivery_fee invoice.line_items.where("item ILIKE '%delivery%'").sum(:amount)
      json.invoice_id invoice.id
    else
      json.delivery_fee 0
      json.invoice_id nil 
    end
  end
end
