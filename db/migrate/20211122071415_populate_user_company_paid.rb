class PopulateUserCompanyPaid < ActiveRecord::Migration[5.1]
  def change
    Order.active.each do |order|
      order.update_columns(user_paid: order.user_payable_amount, company_paid: order.company_payable_amount)
    end
  end
end
