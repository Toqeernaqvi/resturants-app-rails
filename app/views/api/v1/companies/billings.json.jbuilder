json.invoice current_member.company.billing
json.address current_member.company.billing.addresses.last
json.approver current_member.company.billing.approvers.last
json.payment_detail current_member.company.billing.customer_id.present?

if current_member.company.billing.customer_id.present? && current_member.company.billing.stripe_cc_id.present?
  id = current_member.company.billing.customer_id
  card_id = current_member.company.billing.stripe_cc_id
  customer = Stripe::Customer.retrieve(id)
  card_details = customer.sources.retrieve(card_id)

  json.card_detail do
    json.last4 card_details.last4
    json.expiry_month card_details.exp_month
    json.expiry_year card_details.exp_year
  end
end
