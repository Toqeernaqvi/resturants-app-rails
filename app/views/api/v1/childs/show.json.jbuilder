json.extract! @company, :id, :name, :status, :user_meal_budget, :time_zone
json.departments @company.childs do |child|
  json.(
    child,
    :id, :name, :status, :user_meal_budget, :time_zone
  )
end
# json.set! "billing" do
#   json.(
#     @bill,
#     :name, :invoice_credit_card
#   )
#   json.address @bill.addresses.last
#   json.approver @bill.approvers.last
#   json.payment_detail @bill.customer_id.present?
#   if @bill.customer_id.present? && @bill.stripe_cc_id.present?
#     id = @bill.customer_id
#     card_id = @bill.stripe_cc_id
#     customer = Stripe::Customer.retrieve(id)
#     card_details = customer.sources.retrieve(card_id)
#     json.card_detail do
#       json.last4 card_details.last4
#       json.expiry_month card_details.exp_month
#       json.expiry_year card_details.exp_year
#     end
#   end
# end