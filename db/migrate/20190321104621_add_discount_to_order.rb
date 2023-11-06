class AddDiscountToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :discount, :decimal, :default => 0
  end
end
