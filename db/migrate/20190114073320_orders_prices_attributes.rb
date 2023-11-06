class OrdersPricesAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :company_price, :decimal, default: 0, :precision => 8, :scale => 2, after: :price
    add_column :orders, :user_price, :decimal, default: 0, :precision => 8, :scale => 2, after: :company_price
    add_column :orders, :site_price, :decimal, default: 0, :precision => 8, :scale => 2, after: :user_price
  end
end
