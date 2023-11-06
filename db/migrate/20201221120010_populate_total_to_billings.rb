class PopulateTotalToBillings < ActiveRecord::Migration[5.1]
  def self.up
    RestaurantBilling.all.each do |billing|
      quantity = billing.orders.active.sum(:quantity)
      total_payout = billing.food_total - billing.commission + billing.sales_tax - billing.credit_card_fees + billing.tips - billing.adjustments.sum(&:price)
      billing.update_columns(quantity_total: quantity, payout_total: total_payout)
    end
  end

  def self.down
    RestaurantBilling.update_all(quantity_total: 0, payout_total: 0.0)
  end
end
