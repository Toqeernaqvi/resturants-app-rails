class OptionsOrdersOrderId < ActiveRecord::Migration[5.1]
  def change
    add_reference :options_orders, :order, index: true, foreign_key: true, after: :option_id
  end
end
