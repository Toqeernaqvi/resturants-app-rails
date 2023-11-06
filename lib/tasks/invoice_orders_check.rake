namespace :invoice_check do
  desc "Task to Check orders tied to invoice"
  task invoice_check: :environment do
    Invoice.invoice_check
  end

  task restaurant_billing_check: :environment do
    Order.missed_restaurant_billing
  end
end
