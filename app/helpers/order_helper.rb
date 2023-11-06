module OrderHelper
  def self.orders_billing(orders)
    billing = Hash.new
    billing["enable_self_service"] = false
    billing["sub_total"] = billing["sale_tax_percentage"] = billing["sale_tax"] = billing["discount_percentage"] = billing["commission"] = billing["delivery_cost"] = billing["payout_total"] = 0
    
    return billing if orders.blank?
    # address = RestaurantAddress.find_by_id address_id
    # buffet_menu_type = (orders.class.equal?(Array) ? Runningmenu.menu_types.keys[orders.first.menu_type] : orders.last.runningmenu.menu_type) == 'buffet'
    if orders.class.equal?(Array)
      # option_total = (sprintf "%.2f", (orders.map{|o| o.active? && o.options.present? ? o.options_price * o.quantity : 0 }.sum)).to_f
      # food_total = (sprintf "%.2f", (orders.map{|o| o.order_status == 'active' || o.order_status.empty? ? o.food_price_total : 0}.sum)).to_f
      food_total = orders.map{|o| o.order_status == 'active' || o.order_status.empty? ? o.food_price_total : 0}.sum
      # billing["discount_percentage"] = buffet_menu_type && (orders.sum(&:quantity) >= address.items_count || food_total >= address.minimum_discount_price) ? (address.add_contract_commission ? (address.discount_percentage + address.buffet_commission) : address.buffet_commission) : (buffet_menu_type ? 0 : address.discount_percentage)
      # billing["sale_tax_percentage"] = TaxRate.exists?(zip: address.zip) ? TaxRate.find_by(zip: address.zip).estimated_combined_rate : 0.0925
      # billing["sub_total"] = food_total
      # billing["commission"] = (sprintf "%.2f", ((billing["sub_total"] * billing["discount_percentage"])/100) ).to_f
      # billing["sale_tax"] = (sprintf "%.2f", (billing["sub_total"] * billing["sale_tax_percentage"])).to_f
      # billing["payout_total"] = sprintf('%.2f', (billing["sub_total"] - billing["commission"] + billing["sale_tax"]))
      # billing
    else
      food_total = orders.map{|o| o.status == 'active' ? o.food_price_total : 0}.sum
      # billing["discount_percentage"] = buffet_menu_type && (orders.sum(&:quantity) >= address.items_count || food_total >= address.minimum_discount_price) ? (address.add_contract_commission ? (address.discount_percentage + address.buffet_commission) : address.buffet_commission) : (buffet_menu_type ? 0 : address.discount_percentage)
      # billing["sale_tax_percentage"] = TaxRate.exists?(zip: address.zip) ? TaxRate.find_by(zip: address.zip).estimated_combined_rate : 0.0925
      # billing["sub_total"] = food_total
      # billing["commission"] = (sprintf "%.2f", ((billing["sub_total"] * billing["discount_percentage"])/100) ).to_f
      # billing["sale_tax"] = (sprintf "%.2f", (billing["sub_total"] * billing["sale_tax_percentage"])).to_f
      # billing["payout_total"] = sprintf('%.2f', (billing["sub_total"] - billing["commission"] + billing["sale_tax"]))
      # billing
    end
    restaurant_address = RestaurantAddress.find(orders.first.restaurant_address_id)
    runningmenu = Runningmenu.find(orders.first.runningmenu_id)
    delivery_cost = restaurant_address.enable_self_service && runningmenu.delivery? ? restaurant_address.delivery_cost : 0.0
    billing["enable_self_service"] = restaurant_address.enable_self_service
    billing["delivery_meeting"] = runningmenu.delivery?
    billing["sub_total"] = food_total
    billing["sale_tax_percentage"] = orders.blank? ? "" : orders.first.sales_tax_rate*100
    billing["sale_tax"] = orders.sum(&:sales_tax)&.round(2)
    billing["discount_percentage"] = food_total > 0 ? (orders.sum(&:restaurant_commission)/food_total * 100)&.round(2) : 0.0
    billing["commission"] = orders.sum(&:restaurant_commission)&.round(2)
    billing["delivery_cost"] = delivery_cost
    billing["payout_total"] = orders.sum(&:restaurant_payout)&.round(2) + delivery_cost
    billing
  end
end
