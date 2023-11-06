class AddUserPaidCompanyPaidToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :user_paid, :decimal, default: 0, :precision => 8, :scale => 2
    add_column :orders, :company_paid, :decimal, default: 0, :precision => 8, :scale => 2
  end
end
