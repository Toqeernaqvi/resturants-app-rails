class WebhookMailer < ApplicationMailer

  def webhook_email(params, subject)
    @params = params
    mail(to: 'amir@codility.co' , subject: subject)
  end

  def quickbook_error(message, obj_id, klass)
    @message = message
    # if klass == "Invoice"
    #   @klass = "Invoice"
    #   @link = "#{ENV["BACKEND_HOST"]}/admin/invoices/#{obj_id}" 
    #   @current_date = Time.current.in_time_zone(Invoice.find_by(id: obj_id).company.time_zone)
    # else
    #   @klass = "Restaurant Billing"
    #   @link = "#{ENV["BACKEND_HOST"]}/admin/restaurant_billings/#{obj_id}"
    #   @current_date = Time.current.in_time_zone(RestaurantBilling.find_by(id: obj_id).restaurant.time_zone)
    # end 

    if klass == "Invoice"
      @link = "#{ENV["BACKEND_HOST"]}/admin/invoices/#{obj_id}"
    elsif klass == "PaymentLog"
      @link = "#{ENV["BACKEND_HOST"]}/admin/payment_logs/#{obj_id}"
    else
      @link = "#{ENV["BACKEND_HOST"]}/admin/restaurant_billings/#{obj_id}"
    end
    @klass = klass
    mail(to: ENV['FINANCE_EMAIL'] , subject: "Quick Book #{klass} Error")
  end

end
