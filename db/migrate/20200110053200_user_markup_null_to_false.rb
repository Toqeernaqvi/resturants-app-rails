class UserMarkupNullToFalse < ActiveRecord::Migration[5.1]
  def change
    Order.where(user_markup: nil).update_all(user_markup: false)
  end
end
