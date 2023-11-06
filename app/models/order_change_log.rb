class OrderChangeLog < ApplicationRecord
  belongs_to :order

  after_commit :update_order, on: :create
  
  def update_order
    self.order.update_columns(new_items_in_last24_hours: OrderChangeLog.where(order_id: self.order_id, updated_at: Time.current-1.day..Time.current).sum(:order_quantity))
  end
end
