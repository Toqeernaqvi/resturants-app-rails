class PopulateFoodPrice < ActiveRecord::Migration[5.1]
  def change
    Order.all.includes(:fooditem, optionsets_orders:[options_orders:[:option]]).each do |order|
      if order.fooditem.present?
        total = order.fooditem.price.to_f
        order.optionsets_orders.each do |optionset_order|
          optionset_order.options_orders.each do |option_order|
            if option_order.option.present?
              total += option_order.option.price.to_f
            end
          end
        end
        order.update_columns(food_price: total, food_price_total: total * order.quantity)
      end
    end
  end
end
