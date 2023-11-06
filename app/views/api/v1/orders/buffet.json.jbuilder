json.appetizer do
  json.orders @grouped_orders[0]&.each do |order|
    json.(order, :id, :quantity, :price, :total_price, :remarks, :orderrating, :rating_count, :average_rating, :ordered_at, :user_paid )
    json.fooditem_image_url order.fooditem.image.url
    json.title order.name
    json.serve_count order.serve_count
    json.optionsets order.optionsets_orders.each do |set|
      json.set_name set.optionset&.name
      json.set_values set.options_orders.collect{|c| c.option&.description}.to_sentence
    end
  end
end
json.entree do
  json.orders @grouped_orders[1]&.each do |order|
    json.(order, :id, :quantity, :price, :total_price, :remarks, :orderrating, :rating_count, :average_rating, :ordered_at, :user_paid )
    json.fooditem_image_url order.fooditem.image.url
    json.title order.name
    json.serve_count order.serve_count
    json.optionsets order.optionsets_orders.each do |set|
      json.set_name set.optionset&.name
      json.set_values set.options_orders.collect{|c| c.option&.description}.to_sentence
    end
  end
end
json.vegetarian_entree do
  json.orders @grouped_orders[2]&.each do |order|
    json.(order, :id, :quantity, :price, :total_price, :remarks, :orderrating, :rating_count, :average_rating, :ordered_at, :user_paid)
    json.fooditem_image_url order.fooditem.image.url
    json.title order.name
    json.serve_count order.serve_count
    json.optionsets order.optionsets_orders.each do |set|
      json.set_name set.optionset&.name
      json.set_values set.options_orders.collect{|c| c.option&.description}.to_sentence
    end
  end
end
json.side do
  json.orders @grouped_orders[3]&.each do |order|
    json.(order, :id, :quantity, :price, :total_price, :remarks, :orderrating, :rating_count, :average_rating, :ordered_at, :user_paid)
    json.fooditem_image_url order.fooditem.image.url
    json.title order.name
    json.serve_count order.serve_count
    json.optionsets order.optionsets_orders.each do |set|
      json.set_name set.optionset&.name
      json.set_values set.options_orders.collect{|c| c.option&.description}.to_sentence
    end
  end
end
json.dessert do
  json.orders @grouped_orders[4]&.each do |order|
    json.(order, :id, :quantity, :price, :total_price, :remarks, :orderrating, :rating_count, :average_rating, :ordered_at, :user_paid)
    json.fooditem_image_url order.fooditem.image.url
    json.title order.name
    json.serve_count order.serve_count
    json.optionsets order.optionsets_orders.each do |set|
      json.set_name set.optionset&.name
      json.set_values set.options_orders.collect{|c| c.option&.description}.to_sentence
    end
  end
end
