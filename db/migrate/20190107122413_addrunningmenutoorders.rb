class Addrunningmenutoorders < ActiveRecord::Migration[5.1]
  def change
    add_reference :orders, :restaurant, index: true, foreign_key: true, after: :user_id
    add_reference :orders, :company, index: true, foreign_key: true, after: :restaurant_id
    add_reference :orders, :address, index: true, foreign_key: true, after: :company_id
    add_reference :orders, :runningmenu, index: true, foreign_key: true, after: :address_id
    add_column :orders, :ordered_at, :date, after: :runningmenu_id
    add_column :orders, :order_type, :integer, default: 0, after: :ordered_at
  end
end
