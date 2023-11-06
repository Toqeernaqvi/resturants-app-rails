json.recipients @invoice.approvers.exists? ? @invoice.approvers.map{ |a| a.email }.join(", ") : @invoice.invoice_email
json.cc ENV['FINANCE_EMAIL']
json.subject "Chowmill Invoice (#{@invoice.invoice_number}) for Delivery on #{@invoice.shipping_subject}"
json.company_name @invoice.company.name
json.shipping_body @invoice.shipping_body