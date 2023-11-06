class PopulateOrdersGroupFormatted < ActiveRecord::Migration[5.1]
  def change
    Order.where('"group" IS NOT NULL').each do |order|
      order.update_column(:formatted_group, order.group_view)
    end
  end
end