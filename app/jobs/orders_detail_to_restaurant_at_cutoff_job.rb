class OrdersDetailToRestaurantAtCutoffJob < ApplicationJob
  queue_as :orders_detail_to_restaurant_at_cutoff

  def perform(runningmenu, address)
    address_runningmenu = AddressesRunningmenu.find_by(runningmenu_id: runningmenu.id, address_id: address.id)
    path = runningmenu.buffet? ? 'admin/orders/buffetsummarypdf.html.erb' : 'admin/orders/ordersummarypdf.html.erb'
    ac = ActionController::Base.new()
    orders = Order.order_summary(runningmenu, false, 0, 0, address.id)
    grouped_orders = Order.order_summary(runningmenu, true, 0, 0, address.id)
    EmailLog.generate_logs(runningmenu, address, address_runningmenu, orders, grouped_orders, path, ac)
    # fax_orders = grouped_orders
    # fax_summary_contacts = address.fax_summary_contacts
    # if fax_orders.present? && fax_summary_contacts.present?
    #   puts "Fax Order History At Cutoff start for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
    #   puts "Found #{fax_orders.count} orders of quantity sum: #{fax_orders.sum{|o| o.quantity} } for address #{address.id} - #{Time.current}"
    #   file_path = "#{fax_orders.first.short_code + "-" if fax_orders.first.short_code.present?}"+"#{fax_orders.first.restaurant_name + '-' }"+"#{Time.now.strftime('%Y%m%d%H%M%S')}.pdf"
    #   ac = ActionController::Base.new()
    #   pdf = ac.render_to_string pdf: file_path, template: path, locals: { orders: fax_orders, delivery_at: runningmenu.delivery_at_timezone, pickup_time: runningmenu.pickup_at_timezone.strftime("%I:%M %p"), fax: true, runningmenu: runningmenu, address_id: address.id}, disposition: 'attachment', encoding: "UTF-8"
    #   save_path = Rails.root.join('public','fax_summary', file_path)
    #   File.open(save_path, 'wb') do |file|
    #     file << pdf
    #   end
    #   s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
    #   bucket_name = ENV['S3_BUCKET_NAME']
    #   @key = "fax/#{file_path}"
    #   @s3_obj = s3.bucket(bucket_name).object(@key)
    #   File.open(save_path, 'rb') do |file|
    #     @s3_obj.put(body: file, acl: 'public-read')
    #   end
    #   pdf_url_key = @s3_obj.key
    #   File.delete(save_path) if File.exist?(save_path)
    #   begin
    #     to = "+1#{fax_summary_contacts&.last&.split("-")&.join()}"
    #     fax_number_count  = Faxlog.pending.where(to: to, created_at: (Time.current-5.minutes).beginning_of_minute..Time.current.end_of_minute).count
    #     if fax_number_count > 1
    #       Faxlog.create(from: ENV['SMS_FROM'], to: to, media_url: pdf_url_key, status: Faxlog.statuses["pending"], file_name: file_path, retry_time: Time.current+fax_number_count*Faxlog::DELAY.minutes)
    #     else
    #       if Rails.env.production?
    #         fax = $twilio_client.fax.faxes.create(from: ENV['SMS_FROM'],to: to, media_url: ENV["S3_BUCKET_URL"]+"/"+pdf_url_key, status_callback: ENV["BACKEND_HOST"]+"/admin/twilio_fax_status/webhook")
    #         if fax.sid.present?
    #           Faxlog.create(from: fax.from, to: fax.to, sid: fax.sid, media_url: pdf_url_key, status: Faxlog.statuses["pending"], file_name: file_path, tries: 1)
    #           puts "Fax sent successfully."
    #         end
    #       end
    #     end
    #   rescue StandardError => e
    #     puts "Fax failed due to #{e.message} - #{Time.current}"
    #   end
    #   puts "Fax Order History At Cutoff end for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
    # else
    #   puts "Fax no contacts found for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
    # end

  end

end
