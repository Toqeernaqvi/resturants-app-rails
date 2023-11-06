json.data do
  json.user @resource
  cords = @resource.current_company_address_cords if @resource.company.present?
  if @resource.restaurant_admin?
    json.order_presence Order.where(created_at: @resource.last_sign_in_at..@resource.current_sign_in_at, restaurant_address_id: @resource.address_id).present?
    json.enable_self_service @resource.addresses.find_by_id(@resource.address_id)&.enable_self_service
  end
  if @resource.company.present?
    json.company do
      json.(
        @resource.company,
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
        :time_zone,
        :image,
        :buffet_addons_markup,
        :enable_marketplace,
        :parent_company_id
      )
      json.budget @resource.company.budget
      json.latitude cords[0]
      json.longitude cords[1]
    end
  else
    json.company @resource.company
  end
end
