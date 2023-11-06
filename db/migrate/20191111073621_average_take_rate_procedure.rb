class AverageTakeRateProcedure < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE VIEW ORDERS_TOTAL_PAYOUT_VIEW AS
      SELECT DATE(runningmenus.delivery_at) as date, orders.count as quantity, fooditems.skip_markup,
        (SUM(orders.total_price-orders.discount) - (SUM(orders.food_price_total) - ((SUM(orders.food_price_total) * (CASE WHEN runningmenus.menu_type = 1 AND (SUM(orders.quantity) >= addresses.items_count OR SUM(orders.food_price_total) >= addresses.minimum_discount_price) THEN (CASE WHEN addresses.add_contract_commission THEN (addresses.discount_percentage + addresses.buffet_commission) ELSE addresses.buffet_commission END) ELSE addresses.discount_percentage END))/100) + ( SUM(orders.food_price_total) * (COALESCE((SELECT tax_rates.estimated_combined_rate FROM tax_rates WHERE zip = addresses.zip), 0.0925))))) as payout
      FROM orders
      INNER JOIN runningmenus ON runningmenus.id = orders.runningmenu_id
      INNER JOIN fooditems ON orders.fooditem_id = fooditems.id
      INNER JOIN restaurant_billings ON restaurant_billings.id = orders.restaurant_billing_id
      INNER JOIN addresses ON restaurant_billings.address_id = addresses.id
      WHERE orders.status = 0
      GROUP BY DATE(runningmenus.delivery_at), addresses.discount_percentage, addresses.zip, restaurant_billings.credit_card_fees, restaurant_billings.tips, runningmenus.menu_type, addresses.id, fooditems.skip_markup;"
  end

  def self.down
    execute "DROP VIEW IF EXISTS ORDERS_TOTAL_PAYOUT_VIEW;";
  end
end
