json.extract! current_member, :id, :email, :first_name, :last_name, :phone_number, :address_id, :user_type
json.user current_member
# json.client_token current_member.client_token
cords = current_member.current_company_address_cords if current_member.company.present?
if current_member.company.present?
  json.company do
    json.(
      current_member.company,
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
      :parent_company_id
    )
    json.budget current_member.company.budget
    json.latitude cords[0]
    json.longitude cords[1]
  end
else
  json.company current_member.company
end

json.selected_cuisines current_member.cuisines_users do |cuisine|
  json.(
    cuisine,
    :id, :cuisine_id
  )
end

json.selected_dietaries current_member.dietaries_users do |dietary|
  json.(
    dietary,
    :id, :dietary_id
  )
end

json.cuisines do
  json.array! Cuisine.active.all do |cuisine|
    json.(
      cuisine,
      :id, :name
    )
  end
end

json.dietaries do
  json.array! Dietary.active.all do |dietary|
    json.(
      dietary,
      :id, :name
    )
  end
end

json.addresses do
  if current_member.company.present?
    json.array! current_member.company.addresses.active do |address|
      json.(
        address,
        :id, :formatted_address
      )
    end
  else
    json.array!
  end
end
json.card_details current_member.card_details