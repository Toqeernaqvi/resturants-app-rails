cords = (current_member.present? && current_member.company_admin?) ? current_member.current_company_address_cords : []
if @share_meeting.present?
  company = @share_meeting.runningmenu.company
else
  company = current_member.company
end
json.company do
  json.(
    company,
    :id,
    :name,
    :user_meal_budget,
    :markup,
    :reduced_markup,
    :reduced_markup_check,
    :user_copay,
    :copay_amount,
    :show_remaining_budget,
    :enable_grouping_orders,
    :image,
    :buffet_addons_markup,
    :enable_marketplace,
    :enable_saas,
    :time_zone,
    :parent_company_id
  )
  json.budget company.budget
  json.latitude cords[0]
  json.longitude cords[1]
end
if @share_meeting.present? && !@share_meeting.customer_id.present?
  json.customer false
elsif current_member.present? && current_member.company.present? && (current_member.company_user? || current_member.unsubsidized_user? || current_member.company_manager?) && current_member.profile_completed? && current_member.customer_id.blank?
  json.customer false
else
  json.customer true
end
json.minimum_amount Setting.min_amount
json.display_intercom Setting.display_intercom
json.card_details @share_meeting.present? ? @share_meeting.card_details : current_member.card_details
json.duplicate_order_exists @meetings_exists
