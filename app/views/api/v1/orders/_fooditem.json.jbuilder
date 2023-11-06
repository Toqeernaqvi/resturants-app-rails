json.(fooditem, :id, :name, :description, :price, :gross_price, :spicy, :best_seller, :skip_markup, :rating_count, :average_rating, :image, :restaurant_name)
json.user_favorite user_favorite(current_member, fooditem)
json.new_fooditem FooditemHelper.new_fooditem(fooditem, current_member)

json.nutritions fooditem.nutritions.where("nutritional_facts.value > 0") do |nutrition|
  json.id nutrition.id
  json.name nutrition.name
  json.value nutrition.value
  json.childs NutritionalFact.joins(:nutrition).where(factable: fooditem, nutritions: {parent_id: nutrition.nutrition_id } ) do |c|
    json.id c.id
    json.name c.nutrition.name
    json.value c.value
  end
end

json.dietaries do
  json.array! fooditem.dietaries do |dietary|
    json.id dietary.id
    json.name dietary.name
  end
end

json.ingredients do
  json.array! fooditem.ingredients do |ingredient|
    json.id ingredient.id
    json.name ingredient.name
  end
end

json.dishsizes do
  json.array! fooditem.dishsizes do |dishsize|
    json.id dishsize.id
    json.title dishsize.title
    json.description dishsize.description
    json.serve_count dishsize.serve_count
    if defined?(order) && order.dishsize.present?
      json.selected dishsize.id == order.dishsize_id
      json.price fooditem.dishsize_fooditems.find_by(dishsize_id: dishsize.id).price + (fooditem.skip_markup || order.runningmenu.company.enable_saas ? 0 : ((fooditem.dishsize_fooditems.find_by(dishsize_id: dishsize.id).price * order.runningmenu.company.buffet_addons_markup) / 100))
    end
  end
end

json.optionsets fooditem.optionsets.active.includes(options: [:ingredients, :dietaries]) do |optionset|
  json.id optionset.id
  json.name optionset.name
  json.required optionset.required
  json.start_limit optionset.start_limit
  json.end_limit optionset.end_limit
  if defined?(order)
    optionsetorder = OptionsetsOrder.find_by(order_id: order.id, optionset_id: optionset.id)
    if optionsetorder.present?
      json.optionsetorder_id optionsetorder.id
      json.selected true
    else
      json.selected false
    end
  end

  json.options optionset.options do |option|
    json.id option.id
    json.description option.description
    json.price option.price

    if defined?(order)
      optionsorder = OptionsOrder.find_by(order_id: order.id, option_id: option.id)
      if optionsorder.present?
        json.optionsorder_id optionsorder.id
        json.selected true
      else
        json.selected false
      end
    end
  end
end