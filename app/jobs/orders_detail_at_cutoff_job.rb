class OrdersDetailAtCutoffJob < ApplicationJob
  queue_as :orders_detail_at_cutoff

  def perform(runningmenu)
    puts "*******Runningmenus At Cutoff Job Start********"    
    
    puts "Order detail at cutoff loop start for #{runningmenu.id} - #{Time.current}"

    orders = runningmenu.orders.active
    if orders.present?
      # save_path = file_name = pdf_url = ""
      if runningmenu.buffet?
        file_name = "Menu-Spread-#{runningmenu.delivery_at_timezone}-#{Time.current.to_i.to_s}"
        uniq_time_stamp = "menu-spread_#{Time.current.to_i.to_s}_#{runningmenu.id}"
        ac = ActionController::Base.new()
        pdf = ac.render_to_string(pdf: file_name, template: 'admin/orders/admin_buffet_summary.html.erb', :formats => [:html], encoding: 'utf8', :layout => false, :locals => {:orders => orders.joins(:fooditem => :sections).order("sections.section_type ASC").uniq, :runningmenu => runningmenu}, margin: {top: 30,bottom: 5})
        save_path = Rails.root.join('public/ordersummary', uniq_time_stamp + '.pdf')
        File.open(save_path, 'wb') do |file|
          file << pdf
        end
        # s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
        bucket_name = ENV['S3_BUCKET_NAME']
        # @key = "adminbuffetpdf/#{file_name}.pdf"
        key = "adminbuffetpdf/#{uniq_time_stamp}.pdf"
        # pdf_url_key = "summarypdf/#{uniq_time_stamp}.pdf"

        # @s3_obj = s3.bucket(bucket_name).object(@key)
        # File.open(save_path, 'rb') do |file|
        #   @s3_obj.put(body: file, acl: 'public-read')
        # end

        # S3UploadJob.perform_later(pdf_url_key, bucket_name, file_name, "ordersummary")
        # S3UploadJob.perform_later(pdf_url_key, bucket_name, uniq_time_stamp, "ordersummary")
        pdf_url_key = EmailLog.upload_to_s3(key, bucket_name, uniq_time_stamp, "ordersummary")
        # puts "*******MENU SPREAD UPLOAD PUBLIC URL********"
        # pdf_url = @s3_obj.public_url
        # pdf_url_key = @s3_obj.key

        # pdf_url = @s3_obj.public_url
        # if pdf_url.present?
        #   puts "#{pdf_url}"
        #   pdf_url_key = pdf_url.split(".com/")[1]
        # else
        #   puts "*******MENU SPREAD UPLOAD OBJECT KEY URL********"
        #   pdf_url_key = @s3_obj.key
        #   puts "#{pdf_url_key}"
        #   puts "*******MENU SPREAD BOTH KEY PRINTED********"
        # end
      end

      puts "Order detail at cutoff for #{runningmenu.id} found #{orders.count} orders - #{Time.current}"
      admin_users = runningmenu.company.company_admins.active
      puts "Order detail at cutoff for #{runningmenu.id} found #{admin_users.present? ? admin_users.count : 0} users"
      admin_users.each do |user|
        admin_orders = orders.where(user_id: user.id)
        begin
          puts "Order detail at cutoff for #{runningmenu.id} sending email to #{user.email} - #{Time.current}"
          if runningmenu.buffet?
            email = OrderMailer.company_order_detail(user, runningmenu, orders, false)
            email_log = EmailLog.new(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
            email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: pdf_url_key) if pdf_url_key.present?
            email_log.save!
            # File.delete(save_path) if File.exist?(save_path)
          else
            uniq_time_stamp = "chowmill-orders_#{Time.current.to_i.to_s}_#{runningmenu.id}"
            file_name = "Chowmill-Orders-#{runningmenu.delivery_at_timezone.strftime('%m-%d-%Y')}.pdf"
            ac = ActionController::Base.new()
            total_items = orders.sum(:quantity).to_i
            pdf = ac.render_to_string(pdf: file_name, template: 'admin/schedules/cheat_sheetpdf.html.erb', locals: { orders: orders, runningmenu: runningmenu, grouped_orders: runningmenu.grouped_orders, ungrouped_orders: runningmenu.ungrouped_orders, total_items: total_items})
            save_path = Rails.root.join('public/ordersummary',uniq_time_stamp + '.pdf')
            File.open(save_path, 'wb') do |file|
              file << pdf
            end
            bucket_name = ENV['S3_BUCKET_NAME']
            key = "cheatsheetpdf/#{uniq_time_stamp}.pdf"
            pdf_url_key = EmailLog.upload_to_s3(key, bucket_name, uniq_time_stamp, "ordersummary")
            email = OrderMailer.company_order_detail(user, runningmenu, orders, false)
            email_log = EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
            email_log.logs_attachments.new(attachment_file_name: file_name,attachment: pdf_url_key) if pdf_url_key.present?
            email_log.save!
          end
        rescue StandardError => e
          puts "orders_at_cutoff failed for user #{user.id}: #{e.message} - #{Time.current}"
        end
      end
    end
    puts "User_orders_at_cutoff loop start for #{runningmenu.id} - #{Time.current}"
    company_users = orders.joins(:user).where("users.user_type IN(#{User.user_types[:company_user]}, #{User.user_types[:company_manager]}, #{User.user_types[:unsubsidized_user]})").pluck(:user_id).uniq
    share_meetings = ShareMeeting.where(runningmenu_id: runningmenu.id)
    company_users.each do |user|
      company_user_orders = orders.where(user_id: user)
      puts "User_orders_at_cutoff for #{runningmenu.id} found #{company_user_orders.exists? ? company_user_orders.count : 0} orders - #{Time.current}"
      user_price = orders.exists?(['user_price > ?', 0.0])
      begin
        puts "User_orders_at_cutoff for #{runningmenu.id} sending email - #{Time.current}"
        email = OrderMailer.company_order_detail(company_user_orders.first.user, runningmenu, company_user_orders, user_price)
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      rescue StandardError => e
        puts "User_orders_at_cutoff failed for user #{user}: #{e.message} - #{Time.current}"
      end
    end

    share_meetings.each do |share_meeting|
      begin
        puts "User_orders_at_cutoff for #{runningmenu.id} and share meeting #{share_meeting.id} sending email - #{Time.current}"
        share_meeting_orders = share_meeting.orders.active
        user_price = share_meeting_orders.exists?(['user_price > ?', 0.0])
        email = OrderMailer.company_order_detail(nil, runningmenu, share_meeting_orders, user_price, share_meeting)
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      rescue StandardError => e
        puts "User_orders_at_cutoff failed for share_meeting #{share_meeting.id}: #{e.message} - #{Time.current}"
      end
    end
    puts "User_orders_at_cutoff loop end for #{runningmenu.id} - #{Time.current}"

    puts "Order detail at cutoff loop end for #{runningmenu.id} - #{Time.current}"
    
    puts "*******Runningmenus At Cutoff Job End********"
  end
end
