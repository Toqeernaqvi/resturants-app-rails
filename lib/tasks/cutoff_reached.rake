namespace :cutoffreached do

  desc "Task for Reminder of cutoff reached"
  task cutoffreached_reminder: :environment do
    # Runningmenu.cutoff_reached_reminder
    # Runningmenu.orders_at_cutoff
    # Runningmenu.user_orders_at_cutoff
    runningmenus_at_cutoff = Runningmenu.approved.where(cutoff_at: Time.current.beginning_of_minute..Time.current.end_of_minute)
    # runningmenus_at_cutoff = Runningmenu.approved.joins(:orders).where("cutoff_at < '#{Time.current}'").limit(10)
    FileUtils.mkdir_p 'public/ordersummary'
    FileUtils.mkdir_p 'public/download_pdfs'
    FileUtils.mkdir_p 'public/fax_summary'
    puts "\n\n\n\n\n\n"
    puts "====================================================================================================================="
    puts "---------------------------------------------------------------------------------------------------------------------"
    puts "One minute Crons Started at #{Time.current}"
    puts "---------------------------------------------------------------------------------------------------------------------"
    puts "=====================================================================================================================\n\n"
    puts "Total count scheduler for cutoff #{runningmenus_at_cutoff.present? ? runningmenus_at_cutoff.count : 0} - #{Time.current}"
    if runningmenus_at_cutoff.present?
      puts "Survey: runningmenu count #{runningmenus_at_cutoff.count}  - #{Time.current}"
      puts "Cutoff Reached Reminder: Start  - #{Time.current}"
      begin
        email = ScheduleMailer.cutoff_at_reached(runningmenus_at_cutoff)
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        Order.assign_groups(runningmenus_at_cutoff)
      rescue StandardError => e
        puts "Cutoff Reached Reminder:: #{e.message} - #{Time.current}"
      end
      puts "Cutoff Reached Reminder End - #{Time.current}"

      puts "Order detail at cutoff processing start for runningmenus count #{runningmenus_at_cutoff.count} - #{Time.current}"      
      runningmenus_at_cutoff.each do |runningmenu|
        # puts "Order detail at cutoff loop start for #{runningmenu.id} - #{Time.current}"
        # order_detail_at_cutoff(runningmenu)
        # puts "Order detail at cutoff loop end for #{runningmenu.id} - #{Time.current}"
        OrdersDetailAtCutoffJob.perform_later(runningmenu)

        runningmenu_addresses = runningmenu.addresses.active
        puts "Order History At Cutoff for restaurant found #{runningmenu_addresses.present? ? runningmenu_addresses.count : 0} - #{Time.current}"
        runningmenu_addresses.each do |address|

          puts "Order History At Cutoff start for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
          OrdersDetailToRestaurantAtCutoffJob.perform_later(runningmenu, address)
          # address_runningmenu = AddressesRunningmenu.find_by(runningmenu_id: runningmenu.id, address_id: address.id)
          # user_orders_present = runningmenu.orders.active.joins(:user).where('users.user_type = ? AND orders.restaurant_address_id= ? OR orders.share_meeting_id IS NOT NULL', User.user_types[:company_user], address.id).exists?
          # if runningmenu.buffet?
          #   path = 'admin/orders/buffetsummarypdf.html.erb'
          # else
          #   path = user_orders_present ? 'admin/orders/userordersummary.html.erb' : 'admin/orders/ordersummarypdf.html.erb'
          # end
          # ac = ActionController::Base.new()
          # curr_time = Time.current
          # remainder_minutes = curr_time.strftime('%M').to_i % ENV["MEETING_EMAILS_INTERVAL"].to_i
          # from = (curr_time - remainder_minutes.minutes).beginning_of_minute
          # to = runningmenu.cutoff_at
          # if user_orders_present
          #   changed_orders = Order.order_summary_user(runningmenu, true, 0, 0, address.id, 0, from.utc.to_s(:db), to.utc.to_s(:db) )#changed orders
          #   all_before_cutoff_orders = Order.order_summary_user(runningmenu, false, 0, 0, address.id) #all active orders
          #   orders = Order.order_summary_user(runningmenu, true, 0, 0, address.id, 1) # active orders with latest_version_id is null
          # else
          #   changed_orders = Order.order_summary(runningmenu, true, 0, 0, address.id, 0, from.utc.to_s(:db), to.utc.to_s(:db))#changed orders
          #   all_before_cutoff_orders = Order.order_summary(runningmenu, false, 0, 0, address.id) #all active orders
          #   orders = Order.order_summary(runningmenu, true, 0, 0, address.id, 1) # active orders with latest_version_id is null
          # end
          # result = Order.order_summary_pdf(changed_orders, all_before_cutoff_orders)
          # billing_orders = result[0]
          # before_cutoff_orders = result[1]
          # if changed_orders.present?
          #   generate_logs_changed_orders(runningmenu, address, address_runningmenu, user_orders_present, changed_orders, billing_orders, before_cutoff_orders, orders, path, ac, '')
          # else
          #   generate_logs(runningmenu, address, address_runningmenu, all_before_cutoff_orders, user_orders_present, path, ac)
          # end
        end
      end
    end

    runningmenus_at_admin_cutoff = Runningmenu.approved.where(admin_cutoff_at: Time.current.beginning_of_minute..Time.current.end_of_minute)
    puts "Total count scheduler for admin cutoff #{runningmenus_at_admin_cutoff.present? ? runningmenus_at_admin_cutoff.count : 0} - #{Time.current}"
    runningmenus_at_admin_cutoff.each do |runningmenu|
      puts "Runningmenu #{runningmenu.id} processing start - #{Time.current}"
      puts "Changes Email At Admin Cutoff start for scheduler #{runningmenu.id} - #{Time.current}"
      orders = Order.find_by_sql("select * from order_at_admin_cutoff(#{runningmenu.id})")
      unless orders.blank?
        puts "Changes Email At Admin Cutoff found #{orders.count} orders - #{Time.current}"
        begin
          email = OrderMailer.orders_diff_at_admin_cuttof(runningmenu, orders)
          EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        rescue StandardError => e
          puts "Changes Email At Admin Cutoff failed due to: #{e.message} - #{Time.current}"
        end
      end

      Order.assign_groups_to_orders_after_cutoff(runningmenus_at_admin_cutoff) rescue ""

      puts "Changes Email At Admin Cutoff  end for scheduler #{runningmenu.id} - #{Time.current}"
      # addresses_at_admin_cutoff = runningmenu.addresses.active
      # puts "Changes Alert to Restaurant addresses count #{addresses_at_admin_cutoff.present? ? addresses_at_admin_cutoff.count : 0} - #{Time.current}"
      addresses_at_admin_cutoff = runningmenu.addresses.active
      addresses_at_admin_cutoff.each do |address|
        puts "Admin Cutoff start for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
        OrdersDetailToRestaurantAtAdminCutoffJob.perform_later(runningmenu, address)
      end
      # addresses_at_admin_cutoff.each do |address|
      #   if runningmenu.orders.joins(:versions).where(versions: { created_at: runningmenu.cutoff_at..runningmenu.admin_cutoff_at }).count > 0
      #     OrdersDetailToRestaurantAtAdminCutoffJob.perform_later(runningmenu, address, fax_numbers)
      #     # address_runningmenu = AddressesRunningmenu.find_by(runningmenu_id: runningmenu.id, address_id: address.id)
      #     # puts "Changes Alert to Restaurant start for address #{address.id} - #{Time.current}"
      #     # user_orders_present = runningmenu.orders.active.joins(:user).where('users.user_type = ? AND orders.restaurant_address_id= ? OR orders.share_meeting_id IS NOT NULL', User.user_types[:company_user], address.id).exists?
      #     # if runningmenu.buffet?
      #     #   path = 'admin/orders/buffetsummarypdf.html.erb'
      #     # else
      #     #   path = user_orders_present ? 'admin/orders/userordersummary.html.erb' : 'admin/orders/ordersummarypdf.html.erb'
      #     # end
      #     # ac = ActionController::Base.new()
      #     # if user_orders_present
      #     #   changed_orders = Order.order_summary_user(runningmenu, true, 0, 0, address.id, 0, runningmenu.cutoff_at.utc.to_s(:db), runningmenu.admin_cutoff_at.utc.to_s(:db))
      #     #   all_before_cutoff_orders = Order.order_summary_user(runningmenu, false, 0, 0, address.id)
      #     #   orders = Order.order_summary_user(runningmenu, true, 0, 0, address.id, 1)
      #     # else
      #     #   changed_orders = Order.order_summary(runningmenu, true, 0, 0, address.id, 0, runningmenu.cutoff_at.utc.to_s(:db), runningmenu.admin_cutoff_at.utc.to_s(:db))
      #     #   all_before_cutoff_orders = Order.order_summary(runningmenu, false, 0, 0, address.id)
      #     #   orders = Order.order_summary(runningmenu, true, 0, 0, address.id, 1)
      #     # end
      #     # result = Order.order_summary_pdf(changed_orders, all_before_cutoff_orders)
      #     # billing_orders = result[0]
      #     # before_cutoff_orders = result[1]
      #     # puts "Changes Email At Admin Cutoff found #{changed_orders.count} changed orders of quantity sum: #{changed_orders.sum{|o| o.quantity} } for address #{address.id} - #{Time.current}"
      #     # if changed_orders.present?
      #     #   generate_logs_changed_orders(runningmenu, address, address_runningmenu, user_orders_present, changed_orders, billing_orders, before_cutoff_orders, orders, path, ac, 'Admin')
      #     # end
      #     # puts "Changes Alert to Restaurant end for address #{address.id} - #{Time.current}"

      #     # if address.contacts.where.not(fax: "", fax_summary_check: false).present?
      #     #   puts "Fax Order History At Cutoff start for address #{address.id} - #{Time.current}"
      #     #   puts "Found #{changed_orders.count} orders of quantity sum: #{changed_orders.sum{|o| o.quantity} } for address #{address.id} - #{Time.current}"
      #     #   @client = Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
      #     #   # address = RestaurantAddress.find_by_id(params[:restaurant_address_id])
      #     #   if changed_orders.present?
      #     #     file_path = "#{changed_orders.first.short_code + "-" if changed_orders.first.short_code.present?}"+"#{changed_orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')} #{runningmenu.id} #{Time.now.strftime('-%a, %d %b %H:%M:%S.pdf')}"
      #     #     pdf = ac.render_to_string pdf: file_path, template: path, locals: { orders: changed_orders, billing_orders: billing_orders, before_cutoff_orders: before_cutoff_orders, delivery_at: runningmenu.delivery_at_timezone, delivery_time: runningmenu.runningmenus_delivery_time(changed_orders), fax: true, runningmenu: runningmenu, order_diff: true, address_id: address.id}, disposition: 'attachment', encoding: "UTF-8"
      #     #     save_path = Rails.root.join('public','fax_summary', file_path)
      #     #     File.open(save_path, 'wb') do |file|
      #     #       file << pdf
      #     #     end
      #     #     s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
      #     #     bucket_name = ENV['S3_BUCKET_NAME']
      #     #     @key = "fax/#{file_path}"
      #     #     @s3_obj = s3.bucket(bucket_name).object(@key)
      #     #     File.open(save_path, 'rb') do |file|
      #     #       @s3_obj.put(body: file, acl: 'public-read')
      #     #     end
      #     #     pdf_url_key = @s3_obj.key
      #     #     File.delete(save_path) if File.exist?(save_path)
      #     #     begin
      #     #       fax_numbers << to = "+1#{address.contacts.where.not(fax: "", fax_summary_check: false)&.last&.fax.split("-").join()}"
      #     #       fax_number_count  = fax_numbers.count(to)
      #     #       if fax_number_count > 1
      #     #         Faxlog.create(from: ENV['SMS_FROM'], to: to, media_url: pdf_url_key, status: Faxlog.statuses["pending"], file_name: file_path, retry_time: Time.current+fax_number_count*Faxlog::DELAY.minutes)
      #     #       else
      #     #         if Rails.env.production?
      #     #           fax = @client.fax.faxes.create(from: ENV['SMS_FROM'],to: to, media_url: ENV["S3_BUCKET_URL"]+"/"+pdf_url_key, status_callback: ENV["BACKEND_HOST"]+"/admin/twilio_fax_status/webhook")
      #     #           if fax.sid.present?
      #     #             Faxlog.create(from: fax.from, to: fax.to, sid: fax.sid, media_url: pdf_url_key, status: Faxlog.statuses["pending"], file_name: file_path, tries: 1)
      #     #             puts "Fax sent successfully."
      #     #           end
      #     #         end
      #     #       end
      #     #     rescue StandardError => e
      #     #       puts "Fax failed due to #{e.message} - #{Time.current}"
      #     #     end
      #     #   else
      #     #     puts "No orders found for #{address.id} - #{Time.current}"
      #     #   end
      #     #   puts "Fax Order History At Cutoff end for address #{address.id} - #{Time.current}"
      #     # else
      #     #   puts "Fax no contacts found for address #{address.id} - #{Time.current}"
      #     # end

      #     # # puts "No changes alert email loop start for address #{address.id} - #{Time.current}"
      #     # # if !runningmenu.orders.active.where(restaurant_address_id: address.id).present? && AddressesRunningmenu.find_by(runningmenu_id: runningmenu.id, address_id: address.id).pre_week_email_sent?
      #     # #   contact = address.contacts.where(email_summary_check: true).first
      #     # #   cc_contacts = address.contacts.where(email_summary_check: true).all[1..-1]&.map{|c| c.email}
      #     # #   if contact.present?
      #     # #     puts "No changes alert email loop contact #{contact.id} found - #{Time.current}"
      #     # #     begin
      #     # #       email = ScheduleMailer.no_changes(runningmenu, contact, address, cc_contacts)
      #     # #       EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, cc: email.cc&.join(', '),recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      #     # #     rescue StandardError => e
      #     # #       puts "No changes email failed due to: #{e.message} - #{Time.current}"
      #     # #     end
      #     # #   end
      #     # # end
      #     # # puts "No changes alert email loop end for address #{address.id} - #{Time.current}"
      #   end
      # end
      runningmenu.generate_invoice_job if runningmenu.delivery? && !runningmenu.enqueued_for_invoice
      puts "Admin cutoff processing end for scheduler #{runningmenu.id} - #{Time.current}"
    end
    puts "\n\n\n---------------------------------------------------------------------------------------------------------------------"
    puts "====================================================================================================================="
  end

  desc "Task for Reminder of Day before buffet delivery"
  task buffet_delivery_reminder: :environment do
    runningmenus_at_cutoff = Runningmenu.approved.where(menu_type: Runningmenu.menu_types[:buffet], delivery_at: Time.current.tomorrow.beginning_of_minute..Time.current.tomorrow.end_of_minute).where("runningmenus.cutoff_at < ?",Time.current.yesterday)
    if runningmenus_at_cutoff.present?
      runningmenus_at_cutoff.each do |runningmenu|
        orders = runningmenu.orders.active
        runningmenu_addresses = runningmenu.addresses.active
        puts "REMINDER: Order History At Cutoff for restaurant found #{runningmenu_addresses.present? ? runningmenu_addresses.count : 0} - #{Time.current}"
        runningmenu_addresses.each do |address|

          puts "REMINDER: Order History At Cutoff start for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
          address_runningmenu = AddressesRunningmenu.find_by(runningmenu_id: runningmenu.id, address_id: address.id)
          user_orders_present = runningmenu.orders.active.joins(:user).where('users.user_type = ? AND orders.restaurant_address_id= ? OR orders.share_meeting_id IS NOT NULL', User.user_types[:company_user], address.id).exists?
          if user_orders_present
            orders = Order.order_summary_user(runningmenu, false, 0, 0, address.id)
          else
            orders = Order.order_summary(runningmenu, false, 0, 0, address.id)
          end
          puts "REMINDER: Order History At Cutoff found #{orders.count} orders of quantity sum: #{orders.sum{|o| o.quantity} } for address #{address.id} - #{Time.current}"
          if orders.present?
            file_name = "#{orders.first.short_code + "-" if orders.first.short_code.present?}"+"#{orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')} #{runningmenu.id}"
            begin
              if address.contacts.present?
                summary_contacts = address.contacts.where(email_summary_check: true)
                if summary_contacts.present?
                  puts "REMINDER: Found #{summary_contacts.count} contacts for address #{address.id} and scheduler #{runningmenu.id} - #{Time.current}"
                  email = ScheduleMailer.orders_for_restaurants_buffet_reminder(runningmenu, orders, address, summary_contacts)
                  email_log = EmailLog.new(sender: email.from.first, cc: email.cc&.join(', '), subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
                  email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: address_runningmenu.summary_pdf)
                  email_log.save
                end
              else
                puts "REMINDER: No contacts Found or scheduler in buffet style for address #{address.id} and scheduler #{runningmenu.id} email will go to order email- #{Time.current}"
                email = ScheduleMailer.orders_for_restaurants_buffet_reminder(runningmenu, orders, address, nil)
                email_log = EmailLog.new(sender: email.from.first, cc: email.cc&.join(', '), subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
                email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: address_runningmenu.summary_pdf)
                email_log.save
              end
            rescue StandardError => e
              puts "REMINDER: Orders_for_restaurants failed due to: #{e.message} - #{Time.current}"
            end

          end
        end
      end
    end
  end

  # def order_detail_at_cutoff(runningmenu)
  #   orders = runningmenu.orders.active
  #   if orders.present?
  #     save_path = file_name = pdf_url = ""
  #     if runningmenu.buffet?
  #       file_name = "Menu-Spread-#{runningmenu.delivery_at_timezone} #{Time.current.to_i}"
  #       ac = ActionController::Base.new()
  #       pdf = ac.render_to_string(pdf: file_name, template: 'admin/orders/admin_buffet_summary.html.erb', :formats => [:html], encoding: 'utf8', :layout => false, :locals => {:orders => orders.joins(:fooditem => :sections).order("sections.section_type ASC"), :runningmenu => runningmenu}, margin: {top: 30,bottom: 5})
  #       save_path = Rails.root.join('public/ordersummary', file_name + '.pdf')
  #       File.open(save_path, 'wb') do |file|
  #         file << pdf
  #       end
  #       s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
  #       bucket_name = ENV['S3_BUCKET_NAME']
  #       @key = "adminbuffetpdf/#{file_name}.pdf"
  #       @s3_obj = s3.bucket(bucket_name).object(@key)
  #       File.open(save_path, 'rb') do |file|
  #         @s3_obj.put(body: file, acl: 'public-read')
  #       end
  #       pdf_url = @s3_obj.public_url
  #       pdf_url_key = @s3_obj.key
  #     end

  #     puts "Order detail at cutoff for #{runningmenu.id} found #{orders.count} orders - #{Time.current}"
  #     admin_users = runningmenu.company.company_admins.active
  #     puts "Order detail at cutoff for #{runningmenu.id} found #{admin_users.present? ? admin_users.count : 0} users"
  #     admin_users.each do |user|
  #       begin
  #         puts "Order detail at cutoff for #{runningmenu.id} sending email to #{user.email} - #{Time.current}"
  #         if runningmenu.buffet?
  #           email = OrderMailer.company_order_detail(user, runningmenu.delivery_at_timezone, orders, false)
  #           email_log = EmailLog.new(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #           email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: pdf_url_key)
  #           email_log.save!
  #           File.delete(save_path) if File.exist?(save_path)
  #         else
  #           email = OrderMailer.company_order_detail(user, runningmenu.delivery_at_timezone, orders, false)
  #           EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #         end
  #       rescue StandardError => e
  #         puts "orders_at_cutoff failed for user #{user.id}: #{e.message} - #{Time.current}"
  #       end
  #     end
  #   end
  #   puts "User_orders_at_cutoff loop start for #{runningmenu.id} - #{Time.current}"
  #   company_users = orders.joins(:user).where('users.user_type = ?', User.user_types[:company_user]).pluck(:user_id).uniq
  #   share_meetings = ShareMeeting.where(runningmenu_id: runningmenu.id)
  #   company_users.each do |user|
  #     company_user_orders = orders.where(user_id: user)
  #     puts "User_orders_at_cutoff for #{runningmenu.id} found #{company_user_orders.exists? ? company_user_orders.count : 0} orders - #{Time.current}"
  #     user_price = orders.exists?(['user_price > ?', 0.0])
  #     begin
  #       puts "User_orders_at_cutoff for #{runningmenu.id} sending email - #{Time.current}"
  #       email = OrderMailer.company_order_detail(company_user_orders.first.user, runningmenu.delivery_at_timezone, company_user_orders, user_price)
  #       EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #     rescue StandardError => e
  #       puts "User_orders_at_cutoff failed for user #{user.id}: #{e.message} - #{Time.current}"
  #     end
  #   end

  #   share_meetings.each do |share_meeting|
  #     begin
  #       puts "User_orders_at_cutoff for #{runningmenu.id} and share meeting #{share_meeting.id} sending email - #{Time.current}"
  #       share_meeting_orders = share_meeting.orders.active
  #       user_price = share_meeting_orders.exists?(['user_price > ?', 0.0])
  #       email = OrderMailer.company_order_detail(nil, runningmenu.delivery_at_timezone, share_meeting_orders, user_price, share_meeting)
  #       EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #     rescue StandardError => e
  #       puts "User_orders_at_cutoff failed for share_meeting #{share_meeting.id}: #{e.message} - #{Time.current}"
  #     end
  #   end
  #   puts "User_orders_at_cutoff loop end for #{runningmenu.id} - #{Time.current}"
  # end

  # def generate_labels_csv(runningmenu, orders, user_orders_present)
  #   if user_orders_present
  #     csv = CSV.open(Rails.root.join('app/assets/csvs/file.csv'), "wb") do |csv|
  #       if orders.first.order_grouping.present? && orders.first.order_grouping != 0
  #         if runningmenu.buffet?
  #           csv << [ "Order Number", "Style", "User Name", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location","Company Location", "Dietary Restrictions", "Ingredients", "Group", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time", ""]
  #         else
  #           csv << [ "Order Number", "User Name", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location","Company Location", "Dietary Restrictions", "Ingredients", "Group", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time", ""]
  #         end
  #         orders.each do |order|
  #           if runningmenu.buffet?
  #             csv << [runningmenu.id, runningmenu.menu_type, order.user_name, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, order.order_group, order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.runningmenus_delivery_time(orders), order.event]
  #           else
  #             alphabets = Order.groups_subgroups(order.order_group)
  #             (1..order.quantity).each_with_index do |o, indx|
  #               csv << [runningmenu.id, order.user_name, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, alphabets[indx], order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.runningmenus_delivery_time(orders), order.event]
  #             end
  #           end
  #         end
  #       else
  #         if runningmenu.buffet?
  #           csv << [ "Order Number", "Style", "User Name", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location","Company Location", "Dietary Restrictions", "Ingredients", "Group", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time", ""]
  #         else
  #           csv << [ "Order Number", "User Name", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location","Company Location", "Dietary Restrictions", "Ingredients", "Group", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time", ""]
  #         end
  #         orders.each do |order|
  #           if runningmenu.buffet?
  #             csv << [runningmenu.id, runningmenu.menu_type, order.user_name, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, order.order_group, order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.runningmenus_delivery_time(orders), order.event]
  #           else
  #             alphabets = Order.groups_subgroups(order.order_group)
  #             (1..order.quantity).each_with_index do |o, indx|
  #               csv << [runningmenu.id, order.user_name, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, alphabets[indx], order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.runningmenus_delivery_time(orders), order.event]
  #             end
  #           end
  #         end
  #       end
  #     end
  #   else
  #     csv = CSV.open(Rails.root.join('app/assets/csvs/file.csv'), "wb") do |csv|
  #       if orders.first.order_grouping.present? && orders.first.order_grouping != 0
  #         if runningmenu.buffet?
  #           csv << [ "Order Number", "Style", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location","Company Location", "Dietary Restrictions", "Ingredients", "Group", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time", ""]
  #         else
  #           csv << [ "Order Number", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location","Company Location", "Dietary Restrictions", "Ingredients", "Group", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time", ""]
  #         end
  #         orders.each do |order|
  #           if runningmenu.buffet?
  #             csv << [ runningmenu.id, runningmenu.menu_type, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, order.order_group, order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.runningmenus_delivery_time(orders), order.event]
  #           else
  #             (1..order.quantity).each do
  #               csv << [ runningmenu.id, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, order.order_group, order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.runningmenus_delivery_time(orders), order.event]
  #             end
  #           end
  #         end
  #       else
  #         if runningmenu.buffet?
  #           csv << [ "Order Number", "Style", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location","Company Location", "Dietary Restrictions", "Ingredients", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time", ""]
  #         else
  #           csv << [ "Order Number", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location","Company Location", "Dietary Restrictions", "Ingredients", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time", ""]
  #         end
  #         orders.each do |order|
  #           if runningmenu.buffet?
  #             csv << [ runningmenu.id, runningmenu.menu_type, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.runningmenus_delivery_time(orders), order.event]
  #           else
  #             (1..order.quantity).each do
  #               csv << [ runningmenu.id, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.runningmenus_delivery_time(orders), order.event]
  #             end
  #           end
  #         end
  #       end
  #     end
  #   end
  # end

  # def generate_logs_changed_orders(runningmenu, address, address_runningmenu, user_orders_present, changed_orders, billing_orders, before_cutoff_orders, orders, path, ac, admin)
  #   allOrders = changed_orders + orders
  #   changed_active_orders = changed_orders.select{|o| o if o.order_status == 'active'}
  #   allLabelsOrders = (changed_orders.select{|o| o if o.order_status == 'active'} + orders).flatten
  #   file_name = "#{changed_orders.first.short_code + "-" if changed_orders.first.short_code.present?}"+"#{changed_orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')} #{runningmenu.id} #{Time.now.strftime('-%a, %d %b %H:%M:%S.pdf')}"
  #   contact = address.contacts.where(email_summary_check: true).first
  #   cc_contacts = address.contacts.where(email_summary_check: true).all[1..-1]&.map{|c| c.email}
  #   pdf = ac.render_to_string(pdf: "#{changed_orders.first.short_code + "-" if changed_orders.first.short_code.present?}"+"#{changed_orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')}", template: path, locals: { orders: changed_orders, billing_orders: billing_orders, before_cutoff_orders: before_cutoff_orders, delivery_at: runningmenu.delivery_at_timezone, delivery_time: runningmenu.runningmenus_delivery_time(changed_orders), runningmenu: runningmenu, order_diff: true, address_id: address.id}, encoding: "UTF-8")
  #   save_path = Rails.root.join('public/download_pdfs', file_name)
  #   File.open(save_path, 'wb') do |file|
  #     file << pdf
  #   end

  #   s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
  #   bucket_name = ENV['S3_BUCKET_NAME']
  #   @key = "summarypdf/#{file_name}"
  #   @s3_obj = s3.bucket(bucket_name).object(@key)
  #   File.open(save_path, 'rb') do |file|
  #     @s3_obj.put(body: file, acl: 'public-read')
  #   end
  #   pdf_url_key = @s3_obj.key
  #   if orders.present?
  #     all_order_file_name = "#{allOrders.first.short_code + "-" if allOrders.first.short_code.present?}"+"#{allOrders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')} #{runningmenu.id} #{Time.now.strftime('-%a, %d %b %H:%M:%S.pdf')}"
  #     pdf = ac.render_to_string(pdf: "#{allOrders.first.short_code + "-" if allOrders.first.short_code.present?}"+"#{allOrders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')}", template: path, locals: { orders: allOrders, billing_orders: billing_orders, before_cutoff_orders: before_cutoff_orders, delivery_at: runningmenu.delivery_at_timezone, delivery_time: runningmenu.runningmenus_delivery_time(allOrders), runningmenu: runningmenu, order_diff: true, address_id: address.id}, encoding: "UTF-8")
  #     all_orders_save_path = Rails.root.join('public/download_pdfs', all_order_file_name)
  #     File.open(all_orders_save_path, 'wb') do |file|
  #       file << pdf
  #     end

  #     s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
  #     bucket_name = ENV['S3_BUCKET_NAME']
  #     @key = "summarypdf/#{all_order_file_name}"
  #     @all_order_s3_obj = s3.bucket(bucket_name).object(@key)
  #     File.open(all_orders_save_path, 'rb') do |file|
  #       @all_order_s3_obj.put(body: file, acl: 'public-read')
  #     end
  #     all_order_pdf_url_key = @all_order_s3_obj.key
  #     address_runningmenu.update(summary_pdf: all_order_pdf_url_key)
  #   else
  #     address_runningmenu.update(summary_pdf: pdf_url_key)
  #   end
  #   label_url_key = nil
  #   # if (address.contacts.exists?(email_label_check: true) || !address.contacts.present?) && !runningmenu.buffet? #commented out due to download url not found at vendor portal.
  #   # summary labels url start
  #   puts "Label maker At #{admin} Cutoff start for address #{address.id} - #{Time.current}"
  #   puts "Label maker At #{admin} Cutoff found #{changed_orders.count} orders of quantity sum: #{changed_orders.sum{|o| o.quantity} } for address #{address.id} - #{Time.current}"
  #   if changed_active_orders.any?
  #     generate_labels_csv(runningmenu, changed_active_orders, user_orders_present)
  #     puts "**************************************Label maker request init at #{Time.current}************************************************************************"
  #     request = RestClient::Request.new(:method => :post, :url => "#{ENV['LABELS_PORTAL_URL']}/process.php", :payload => {:multipart => true, :file => File.new(Rails.root.join('app/assets/csvs/file.csv'), 'rb')})
  #     begin
  #       response = request.execute
  #       puts "**************************************Label maker request executed at #{Time.current}************************************************************************"
  #       labels_save_path = Rails.root.join('public','ordersummary',"#{response.body.split("/")[1]}")
  #       File.open(labels_save_path, 'wb') do |file|
  #         file << open("#{ENV['LABELS_PORTAL_URL']}/#{response.body}").read
  #       end
  #       s3_label = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
  #       bucket_name = ENV['S3_BUCKET_NAME']
  #       @label_key = "summarylabels/#{response.body.split("/")[1]}"
  #       @s3_label_obj = s3_label.bucket(bucket_name).object(@label_key)
  #       File.open(labels_save_path, 'rb') do |file|
  #         @s3_label_obj.put(body: file, acl: 'public-read')
  #       end
  #       puts "Label maker labels file saved to s3 at #{Time.current}"
  #       label_url_key = @s3_label_obj.public_url.present? ? @s3_label_obj.key : nil
  #     rescue StandardError => e
  #       label_url_key = nil
  #       puts "Labels Doc failed for runningmenu #{runningmenu.id} and address #{address.id} due to #{e.message}"
  #     end
  #   else
  #     label_url_key = nil
  #   end

  #   puts "Label maker At #{admin} Cutoff start for address #{address.id} - #{Time.current}"
  #   puts "Label maker At #{admin} Cutoff found #{changed_active_orders.count}  active orders of quantity sum: #{changed_active_orders.sum{|o| o.quantity} } for address #{address.id} - #{Time.current}"
  #   if allLabelsOrders.any? && !runningmenu.buffet?
  #     generate_labels_csv(runningmenu, allLabelsOrders, user_orders_present)
  #     puts "**************************************Label maker request init at #{Time.current}************************************************************************"
  #     request = RestClient::Request.new(:method => :post, :url => "#{ENV['LABELS_PORTAL_URL']}/process.php", :payload => {:multipart => true, :file => File.new(Rails.root.join('app/assets/csvs/file.csv'), 'rb')})
  #     begin
  #       response = request.execute
  #       puts "**************************************Label maker request executed at #{Time.current}************************************************************************"
  #       all_labels_save_path = Rails.root.join('public','ordersummary',"#{response.body.split("/")[1]}")
  #       File.open(all_labels_save_path, 'wb') do |file|
  #         file << open("#{ENV['LABELS_PORTAL_URL']}/#{response.body}").read
  #       end
  #       s3_label = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
  #       bucket_name = ENV['S3_BUCKET_NAME']
  #       @all_labels_key = "summarylabels/#{response.body.split("/")[1]}"
  #       @s3_all_label_obj = s3_label.bucket(bucket_name).object(@all_labels_key)
  #       File.open(all_labels_save_path, 'rb') do |file|
  #         @s3_all_label_obj.put(body: file, acl: 'public-read')
  #       end
  #       puts "Label maker labels file saved to s3 at #{Time.current}"
  #       all_labels_url_key = @s3_all_label_obj.key
  #       address_runningmenu.update(summary_labels: all_labels_url_key)
  #     rescue StandardError => e
  #       puts "Labels Doc failed for runningmenu #{runningmenu.id} and address #{address.id} due to #{e.message}"
  #     end
  #   end
  #   puts "Label maker At #{admin} Cutoff end for address #{address.id} - #{Time.current}"
  #   # summary labels url end
  #   begin
  #     if runningmenu.buffet?
  #       label_summary_contacts = nil
  #       summary_contacts = address.contacts.where(email_summary_check: true)
  #     else
  #       label_summary_contacts = address.contacts.where(email_summary_check: true, email_label_check: true)
  #       summary_contacts = address.contacts.where(email_summary_check: true, email_label_check: false)
  #     end
  #     if label_summary_contacts.present?
  #       puts "Found #{label_summary_contacts.count} contacts for address #{address.id} and scheduler #{runningmenu.id} - #{Time.current}"
  #       email = ScheduleMailer.changes_to_restaurant(runningmenu, changed_orders, address, label_summary_contacts.first, user_orders_present ? true : false , file_name, label_summary_contacts.all[1..-1]&.map{|c| c.email}, before_cutoff_orders, admin.blank? ? 'Reminder:' : 'Updated')
  #       email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #       email_log.logs_attachments.new(attachment_file_name: file_name, attachment: pdf_url_key)
  #       if label_url_key.present?
  #         email_log.logs_attachments.new(attachment_file_name: "Labels.docx", attachment: label_url_key)
  #       end
  #       email_log.save
  #     end
  #     if summary_contacts.present?
  #       puts "Found #{summary_contacts.count} contacts for address #{address.id} and scheduler #{runningmenu.id} - #{Time.current}"
  #       email = ScheduleMailer.changes_to_restaurant(runningmenu, changed_orders, address, summary_contacts.first, user_orders_present ? true : false , file_name, summary_contacts.all[1..-1]&.map{|c| c.email}, before_cutoff_orders, admin.blank? ? 'Reminder:' : 'Updated')
  #       email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #       email_log.logs_attachments.new(attachment_file_name: file_name, attachment: pdf_url_key)
  #       email_log.save
  #     end
  #     unless address.contacts.present?
  #       puts "No contacts Found for address #{address.id} and scheduler #{runningmenu.id} email will go to order email- #{Time.current}"
  #       email = ScheduleMailer.changes_to_restaurant(runningmenu, changed_orders, address, nil, user_orders_present ? true : false , file_name, cc_contacts, before_cutoff_orders, admin.blank? ? 'Reminder:' : 'Updated')
  #       email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #       email_log.logs_attachments.new(attachment_file_name: file_name, attachment: pdf_url_key)
  #       if label_url_key.present?
  #         email_log.logs_attachments.new(attachment_file_name: "Labels.docx", attachment: label_url_key)
  #       end
  #       email_log.save
  #     end

  #   rescue StandardError => e
  #     puts "Changes_to_restaurant failed due to: #{e.message} - #{Time.current}"
  #   end
  # end

  # def generate_logs(runningmenu, address, address_runningmenu, orders, user_orders_present, path, ac)
  #   if orders.present?
  #     uniq_time_stamp = "#{Time.current.to_i.to_s}"
  #     file_name = "#{orders.first.short_code + "-" if orders.first.short_code.present?}"+"#{orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')} #{runningmenu.id}"
  #     # if Dir.entries("#{Rails.root}/public/download_pdfs/").include?(file_name)
  #     #   random_number= rand(0..5000)
  #     #   file_name = "#{orders.first.short_code + "-" if orders.first.short_code.present?}"+"#{orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at.strftime('%a, %d %b %Y %H:%M:%S')} (#{random_number}) #{runningmenu.id}.pdf"
  #     # end
  #     pdf = ac.render_to_string(pdf: "#{orders.first.short_code + "-" if orders.first.short_code.present?}"+"#{orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')}", template: path, locals: { orders: orders, billing_orders: nil, before_cutoff_orders: nil, delivery_at: runningmenu.delivery_at_timezone, delivery_time: runningmenu.runningmenus_delivery_time(orders), runningmenu: runningmenu, order_diff: false, address_id: address.id}, encoding: "UTF-8")
  #     save_path = Rails.root.join('public/download_pdfs', uniq_time_stamp + '.pdf')
  #     File.open(save_path, 'wb') do |file|
  #       file << pdf
  #     end
  #     puts "Making order summary for #{orders.count} orders of quantity sum: #{orders.sum{|o| o.quantity} } for address #{address.id} - #{Time.current}"
  #     s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
  #     bucket_name = ENV['S3_BUCKET_NAME']
  #     @key = "summarypdf/#{uniq_time_stamp}.pdf"
  #     @s3_obj = s3.bucket(bucket_name).object(@key)
  #     File.open(save_path, 'rb') do |file|
  #       @s3_obj.put(body: file, acl: 'public-read')
  #     end
  #     pdf_url_key = @s3_obj.key
  #     File.delete(save_path) if File.exist?(save_path)
  #     address_runningmenu.update(summary_pdf: pdf_url_key)
  #     label_url_key = nil
  #     # if (address.contacts.exists?(email_label_check: true)  || !address.contacts.present?) && !runningmenu.buffet? # commented out due to no url at vendor issue.
  #     # summary labels url start
  #     puts "Label maker At Cutoff start for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
  #     puts "Making labels csv for #{orders.count} orders of quantity sum: #{orders.sum{|o| o.quantity} } for address #{address.id} - #{Time.current}"
  #     generate_labels_csv(runningmenu, orders, user_orders_present)
  #     puts "**************************************Label maker request init at #{Time.current}************************************************************************"
  #     request = RestClient::Request.new(:method => :post, :url => "#{ENV['LABELS_PORTAL_URL']}/process.php", :payload => {:multipart => true, :file => File.new(Rails.root.join('app/assets/csvs/file.csv'), 'rb')})
  #     begin
  #       response = request.execute
  #       puts "**************************************Label maker request executed at #{Time.current}************************************************************************"
  #       labels_save_path = Rails.root.join('public','ordersummary', uniq_time_stamp + '.docx')
  #       File.open(labels_save_path, 'wb') do |file|
  #         file << open("#{ENV['LABELS_PORTAL_URL']}/#{response.body}").read
  #       end
  #       s3_label = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
  #       bucket_name = ENV['S3_BUCKET_NAME']
  #       @label_key = "summarylabels/#{uniq_time_stamp}.docx"
  #       @s3_label_obj = s3_label.bucket(bucket_name).object(@label_key)
  #       File.open(labels_save_path, 'rb') do |file|
  #         @s3_label_obj.put(body: file, acl: 'public-read')
  #       end
  #       puts "Label maker labels file saved to s3 at #{Time.current}"
  #       label_url_key = @s3_label_obj.key
  #       File.delete(labels_save_path) if File.exist?(labels_save_path)
  #       address_runningmenu.update(summary_labels: label_url_key)
  #     rescue StandardError => e
  #       label_url_key = nil
  #       puts "Labels Doc failed for runningmenu #{runningmenu.id} and address #{address.id} due to #{e.message}"
  #     end
  #     puts "Label maker At Cutoff end for address #{address.id} and runningmenu #{runningmenu.id}- #{Time.current}"
  #     # summary labels url end

  #     begin
  #       if runningmenu.buffet?
  #         label_summary_contacts = nil
  #         summary_contacts = address.contacts.where(email_summary_check: true)
  #       else
  #         label_summary_contacts = address.contacts.where(email_summary_check: true, email_label_check: true)
  #         summary_contacts = address.contacts.where(email_summary_check: true, email_label_check: false)
  #       end
  #       if label_summary_contacts.present?
  #         puts "Found #{label_summary_contacts.count} contacts for address #{address.id} and scheduler #{runningmenu.id} - #{Time.current}"
  #         email = ScheduleMailer.changes_to_restaurant(runningmenu, [], address, label_summary_contacts.first, user_orders_present ? true : false , file_name, label_summary_contacts.all[1..-1]&.map{|c| c.email}, orders, 'Reminder:')
  #         email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #         email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: pdf_url_key)
  #         if label_url_key.present?
  #           email_log.logs_attachments.new(attachment_file_name: file_name + '.docx', attachment: label_url_key)
  #         end
  #         email_log.save
  #       end
  #       if summary_contacts.present?
  #         puts "Found #{summary_contacts.count} contacts for address #{address.id} and scheduler #{runningmenu.id} - #{Time.current}"
  #         email = ScheduleMailer.changes_to_restaurant(runningmenu, [], address, summary_contacts.first, user_orders_present ? true : false , file_name, summary_contacts.all[1..-1]&.map{|c| c.email}, orders, 'Reminder:')
  #         email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #         email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: pdf_url_key)
  #         email_log.save
  #       end
  #       unless address.contacts.present?
  #         puts "No contacts Found or scheduler in buffet style for address #{address.id} and scheduler #{runningmenu.id} email will go to order email- #{Time.current}"
  #         email = ScheduleMailer.changes_to_restaurant(runningmenu, [], address, nil, user_orders_present ? true : false , file_name, cc_contacts, orders, 'Reminder:')
  #         email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #         email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: pdf_url_key)
  #         if label_url_key.present?
  #           email_log.logs_attachments.new(attachment_file_name: file_name + '.docx', attachment: label_url_key)
  #         end
  #         email_log.save
  #       end
  #     rescue StandardError => e
  #       puts "Orders_for_restaurants failed due to: #{e.message} - #{Time.current}"
  #     end
  #     puts "Order History At Cutoff for restaurant end for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
  #   end
  # end

end
