json.enable_grouping_orders @runningmenu.company.enable_grouping_orders
json.orders do
  company_id = current_member.present? ? current_member.company_id : @share_meeting.runningmenu.company_id
  @active_orders = @runningmenu.orders.active.joins(:runningmenu, :user).where("runningmenus.company_id = ?", company_id)
  if current_member && (current_member.company_user? || current_member.unsubsidized_user? || current_member.company_manager?) && @runningmenu.individual?
    orders = @active_orders.where(user_id: current_member.id).order("LOWER(users.first_name) ASC, LOWER(users.last_name) ASC").select('orders.id, orders.group, orders.user_id, remarks, quantity, fooditem_id, share_meeting_id')
  elsif (current_member && current_member.company_admin?) || @runningmenu.buffet?
    orders = @active_orders.joins("LEFT JOIN share_meetings ON share_meetings.id = orders.share_meeting_id ").select('CASE WHEN orders.share_meeting_id IS NULL THEN LOWER(users.first_name) ELSE LOWER(share_meetings.first_name) END AS firstname, CASE WHEN orders.share_meeting_id IS NULL THEN LOWER(users.last_name) ELSE LOWER(share_meetings.last_name) END AS lastname, orders.id, orders.group, orders.user_id, remarks, quantity, fooditem_id, share_meeting_id').order("firstname ASC, lastname ASC")
  elsif @share_meeting.present?
    orders = @share_meeting.orders.active.joins(:user).order("LOWER(users.first_name) ASC, LOWER(users.last_name) ASC").select('orders.id, orders.group, orders.user_id, remarks, quantity, fooditem_id, share_meeting_id')
  end
  json.array! orders.all do |booked|
    json.group booked.group_view
    if current_member.present? && current_member.company_admin?
      json.username booked.user.name
    end
    json.(
      booked,
      :id, :remarks, :quantity, :share_meeting, :fooditem
    )
    json.set! 'options' do
      booked.optionsets_orders.each do |optionset_order|
        json.array! optionset_order.options_orders do |option_order|
          json.description option_order.option&.description
        end
      end
    end
    json.cutoff_at @runningmenu.cutoff_at
    json.admin_cutoff_at @runningmenu.admin_cutoff_at
  end
end