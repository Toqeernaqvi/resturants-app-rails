class EmailLog < ApplicationRecord
  enum status: [:pending, :sent, :failed, :cancelled]
  before_update :encode_body, if: lambda{|e| e.body_changed?}
  has_many :logs_attachments, dependent: :destroy
  accepts_nested_attributes_for :logs_attachments

  after_create_commit :set_job_to_send_emails


  def set_job_to_send_emails
    n = ['Welcome to Chowmill', 'Reset password instructions'].include?(self.subject) ? 0 : rand(1..2)
    worker_job_id = MailerWorker.perform_at((Time.current+n.minutes).utc, self.id)
    self.update_column(:job_id, worker_job_id)
  end

  def encode_body
    self.body = Base64.encode64(self.body)
  end

  # def self.send_emails
  #   FileUtils.mkdir_p 'public/email_logs'
  #   time_check = false
  #   file_exists = File.exist?(Rails.root.join('public', 'email_logs', 'logfile.txt'))
  #   if file_exists
  #     file = File.open(Rails.root.join('public', 'email_logs', 'logfile.txt'), 'r')
  #     content = file.read
  #     time_check = content.present? ? (Time.current > content.to_datetime) : false
  #     if time_check
  #       File.delete(Rails.root.join('public', 'email_logs', 'logfile.txt'))
  #     end
  #   end
  #   if (file_exists && time_check) || !file_exists
  #     File.open(Rails.root.join('public', 'email_logs', 'logfile.txt'), 'w'){|f| f.write(Time.current + 10.minutes) }
  #     mails = EmailLog.pending.order('id ASC').limit(50)
  #     mails.each do |mail|
  #       begin
  #         MailerProcessorJob.perform_later(mail)
  #         mail.update(sent_at: Time.current, status: :sent)
  #       rescue StandardError => e
  #         mail.update(failed_at: Time.current, status: :failed)
  #       end
  #     end
  #     File.delete(Rails.root.join('public', 'email_logs', 'logfile.txt')) if File.exist?(Rails.root.join('public', 'email_logs', 'logfile.txt'))
  #   end
  # end

  def self.populate_csv(runningmenu, orders, csv)
    if orders.first.order_grouping.present? && orders.first.order_grouping != 0
      if runningmenu.buffet?
        csv << ["Order Number", "Style", "User Name", "User Type", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location", "Company Location", "Dietary Restrictions", "Ingredients", "Group", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time"]
      else
        csv << ["Order Number", "User Name", "User Type", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location", "Company Location", "Dietary Restrictions", "Ingredients", "Group", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time"]
      end
      orders.each do |order|
        if runningmenu.buffet?
          csv << [runningmenu.id, runningmenu.menu_type, order.user_name, order.user_type, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, order.order_group, order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.pickup_at_timezone.strftime("%I:%M %p")]
        else
          alphabets = Order.groups_subgroups(order.order_group)
          (1..order.quantity).each_with_index do |o, indx|
            csv << [runningmenu.id, order.user_name, order.user_type, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, alphabets[indx], order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.pickup_at_timezone.strftime("%I:%M %p")]
          end
        end
      end
    else
      if runningmenu.buffet?
        csv << ["Order Number", "Style", "User Name", "User Type", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location", "Company Location", "Dietary Restrictions", "Ingredients", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time"]
      else
        csv << ["Order Number", "User Name", "User Type", "Item Name", "Options", "Extra Instructions", "Item Description", "Short Code", "Delivery Instructions", "Restaurant Name", "Restaurant Location", "Company Location", "Dietary Restrictions", "Ingredients", "Driver Name", "Delivery Date", "Delivery Time", "Pickup Time"]
      end
      orders.each do |order|
        if runningmenu.buffet?
          csv << [runningmenu.id, runningmenu.menu_type, order.user_name, order.user_type, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.pickup_at_timezone.strftime("%I:%M %p")]
        else
          (1..order.quantity).each do
            csv << [runningmenu.id, order.user_name, order.user_type, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.fooditem_description, order.short_code, order.delivery_instructions, order.restaurant_name, order.restaurant_location, order.company_location, order.dietary_name, order.ingredient_name, order.driver_name, runningmenu.delivery_at_timezone.strftime("%m/%d/%Y"), runningmenu.delivery_at_timezone.strftime("%H:%M"), runningmenu.pickup_at_timezone.strftime("%I:%M %p")]
          end
        end
      end
    end
  end

  def self.upload_to_s3(key, bucket, uniq_time_stamp, dir_type)
    s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
    s3_obj = s3.bucket(bucket).object(key)
    s3_file_path = ""
    if dir_type == "label"
      labels_save_path = Rails.root.join('public','ordersummary', uniq_time_stamp + '.docx')
      File.open(labels_save_path, 'rb') do |file|
        s3_obj.put(body: file, acl: 'public-read')
      end
      puts "Label maker labels file saved to s3 at #{Time.current}"
      s3_file_path = s3_obj.key
      File.delete(labels_save_path) if File.exist?(labels_save_path)
    elsif dir_type == "pdf"
      save_path = Rails.root.join('public/download_pdfs', uniq_time_stamp + '.pdf')
      File.open(save_path, 'rb') do |file|
        s3_obj.put(body: file, acl: 'public-read')
      end
      puts "Summary pdf file saved to s3 at #{Time.current}"
      s3_file_path = s3_obj.key
      File.delete(save_path) if File.exist?(save_path)
    elsif dir_type == "ordersummary"
      summary_save_path = Rails.root.join('public/ordersummary', uniq_time_stamp + '.pdf')
      File.open(summary_save_path, 'rb') do |file|
        s3_obj.put(body: file, acl: 'public-read')
      end
      puts "Order Summary pdf file saved to s3 at #{Time.current}"
      s3_file_path = s3_obj.key
      File.delete(summary_save_path) if File.exist?(summary_save_path)
    end
    return s3_file_path
  end

  def self.generate_logs(runningmenu, address, address_runningmenu, orders, grouped_orders, path, ac, admin='')
    pdf_url_key = nil
    if orders.present?
      uniq_time_stamp = "#{Time.current.to_i.to_s}_#{runningmenu.id}_#{address_runningmenu&.id}"
      file_name = "#{grouped_orders.first.short_code + "-" if grouped_orders.first.short_code.present?}"+"#{grouped_orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')} #{runningmenu.id}"
      pdf = ac.render_to_string(pdf: "#{grouped_orders.first.short_code + "-" if grouped_orders.first.short_code.present?}"+"#{grouped_orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')}", template: path, locals: { orders: grouped_orders, delivery_at: runningmenu.delivery_at_timezone, pickup_time: runningmenu.pickup_at_timezone.strftime("%I:%M %p"), runningmenu: runningmenu, address_id: address.id}, encoding: "UTF-8")
      save_path = Rails.root.join('public/download_pdfs', uniq_time_stamp + '.pdf')
      File.open(save_path, 'wb') do |file|
        file << pdf
      end
      bucket_name = ENV['S3_BUCKET_NAME']
      key = "summarypdf/#{uniq_time_stamp}.pdf"
      pdf_url_key = EmailLog.upload_to_s3(key, bucket_name, uniq_time_stamp, "pdf")
      address_runningmenu&.update(summary_pdf: pdf_url_key)
      label_url_key = nil
      # summary labels url start
      puts "Label maker At Cutoff start for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
      csv_file_path = Rails.root.join('public/labels_csvs', uniq_time_stamp + '.csv')
      csv = CSV.open(csv_file_path, "wb") do |csv|
        EmailLog.populate_csv(runningmenu, orders, csv)
      end
      puts "**************************************Label maker request init at #{Time.current}************************************************************************"
      # request = RestClient::Request.new(:method => :post, :url => "#{ENV['LABELS_PORTAL_URL']}/process.php", :payload => {:multipart => true, :file => File.new(Rails.root.join('app/assets/csvs/file.csv'), 'rb')})
      request = RestClient::Request.new(:method => :post, :url => "#{ENV['LABELS_PORTAL_URL']}/process.php", :payload => {:multipart => true, :file => File.new(csv_file_path, 'rb')})
      response = request.execute
      puts "**************************************Label maker request executed at #{Time.current}************************************************************************"
      labels_save_path = Rails.root.join('public','ordersummary', uniq_time_stamp + '.docx')
      File.open(labels_save_path, 'wb') do |file|
        file << open("#{ENV['LABELS_PORTAL_URL']}/#{response.body}").read
      end
      bucket_name = ENV['S3_BUCKET_NAME']
      key = "summarylabels/#{uniq_time_stamp}.docx"
      label_url_key = EmailLog.upload_to_s3(key, bucket_name, uniq_time_stamp, "label")
      address_runningmenu&.update(summary_labels: label_url_key)
      File.delete(csv_file_path) if File.exist?(csv_file_path)
      puts "Label maker At Cutoff end for address #{address.id} and runningmenu #{runningmenu.id}- #{Time.current}"
      # summary labels url end

      if runningmenu.buffet?
        label_summary_contacts = nil
        summary_contacts = address.summary_contacts
      else
        label_summary_contacts = address.label_summary_contacts
        summary_contacts = address.summary_without_label_contacts
      end
      if label_summary_contacts.present?
        cc_contacts = label_summary_contacts.drop(1)
        puts "Found #{label_summary_contacts.count} contacts for address #{address.id} and scheduler #{runningmenu.id} - #{Time.current}"
        email = ScheduleMailer.changes_to_restaurant(runningmenu, grouped_orders, address, label_summary_contacts.first, cc_contacts, admin.blank? ? 'Reminder:' : 'Updated')
        email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        email_log.logs_attachments.new(attachment_file_name: 'SUMMARY-' + file_name + '.pdf', attachment: pdf_url_key) if pdf_url_key.present?
        email_log.logs_attachments.new(attachment_file_name: 'LABLES-' + file_name + '.docx', attachment: label_url_key) if label_url_key.present?
        email_log.save
      end
      if summary_contacts.present?
        cc_contacts = summary_contacts.drop(1)
        puts "Found #{summary_contacts.count} contacts for address #{address.id} and scheduler #{runningmenu.id} - #{Time.current}"
        email = ScheduleMailer.changes_to_restaurant(runningmenu, grouped_orders, address, summary_contacts.first, cc_contacts, admin.blank? ? 'Reminder:' : 'Updated')
        email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        email_log.logs_attachments.new(attachment_file_name: 'SUMMARY-' + file_name + '.pdf', attachment: pdf_url_key) if pdf_url_key.present?
        email_log.save
      end
      if summary_contacts.blank? && label_summary_contacts.blank?
        puts "No contacts Found or scheduler in buffet style for address #{address.id} and scheduler #{runningmenu.id} email will go to order email- #{Time.current}"
        email = ScheduleMailer.changes_to_restaurant(runningmenu, grouped_orders, address, nil, nil, admin.blank? ? 'Reminder:' : 'Updated')
        email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        email_log.logs_attachments.new(attachment_file_name: 'SUMMARY-' + file_name + '.pdf', attachment: pdf_url_key) if pdf_url_key.present?
        email_log.logs_attachments.new(attachment_file_name: 'LABLES-' + file_name + '.docx', attachment: label_url_key) if label_url_key.present?
        email_log.save
      end
      puts "Order History At Cutoff for restaurant end for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
    end
  end

  # def self.generate_logs_changed_orders(runningmenu, address, address_runningmenu, changed_orders, billing_orders, before_cutoff_orders, orders, path, ac, admin)
  #   pdf_url_key = nil
  #   uniq_time_stamp = "#{Time.current.to_i.to_s}_#{runningmenu.id}_#{address_runningmenu.id}"
  #   allOrders = changed_orders + orders
  #   changed_active_orders = changed_orders.select{|o| o if o.order_status == 'active'}
  #   allLabelsOrders = (changed_orders.select{|o| o if o.order_status == 'active'} + orders).flatten
  #   file_name = "#{changed_orders.first.short_code + "-" if changed_orders.first.short_code.present?}"+"#{changed_orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')} #{runningmenu.id} #{Time.now.strftime('-%a, %d %b %H:%M:%S')}"
  #   pdf = ac.render_to_string(pdf: "#{changed_orders.first.short_code + "-" if changed_orders.first.short_code.present?}"+"#{changed_orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')}", template: path, locals: { orders: changed_orders, billing_orders: billing_orders, before_cutoff_orders: before_cutoff_orders, delivery_at: runningmenu.delivery_at_timezone, delivery_time: runningmenu.runningmenus_delivery_time(changed_orders), runningmenu: runningmenu, order_diff: true, address_id: address.id}, encoding: "UTF-8")
  #   save_path = Rails.root.join('public/download_pdfs', uniq_time_stamp + '.pdf')
  #   File.open(save_path, 'wb') do |file|
  #     file << pdf
  #   end

  #   bucket_name = ENV['S3_BUCKET_NAME']
  #   key = "summarypdf/#{uniq_time_stamp}.pdf"
  #   # S3UploadJob.perform_later(pdf_url_key, bucket_name, uniq_time_stamp, "pdf")
  #   pdf_url_key = EmailLog.upload_to_s3(key, bucket_name, uniq_time_stamp, "pdf")
    
  #   if orders.present?
  #     uniq_time_stamp = "#{Time.current.to_i.to_s}_#{runningmenu.id}_#{address_runningmenu.id}"
  #     all_order_file_name = "#{allOrders.first.short_code + "-" if allOrders.first.short_code.present?}"+"#{allOrders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')} #{runningmenu.id} #{Time.now.strftime('-%a, %d %b %H:%M:%S.pdf')}"
  #     pdf = ac.render_to_string(pdf: "#{allOrders.first.short_code + "-" if allOrders.first.short_code.present?}"+"#{allOrders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')}", template: path, locals: { orders: allOrders, billing_orders: billing_orders, before_cutoff_orders: before_cutoff_orders, delivery_at: runningmenu.delivery_at_timezone, delivery_time: runningmenu.runningmenus_delivery_time(allOrders), runningmenu: runningmenu, order_diff: true, address_id: address.id}, encoding: "UTF-8")
  #     all_orders_save_path = Rails.root.join('public/download_pdfs', uniq_time_stamp + '.pdf')
  #     File.open(all_orders_save_path, 'wb') do |file|
  #       file << pdf
  #     end
  #     key = "summarypdf/#{uniq_time_stamp}.pdf"
  #     # S3UploadJob.perform_later(all_order_pdf_url_key, bucket_name, uniq_time_stamp, "pdf")
  #     all_order_pdf_url_key = EmailLog.upload_to_s3(key, bucket_name, uniq_time_stamp, "pdf")
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
  #     uniq_time_stamp = "#{Time.current.to_i.to_s}_#{runningmenu.id}_#{address_runningmenu.id}"
  #     EmailLog.generate_labels_csv(runningmenu, changed_active_orders)
  #     puts "**************************************Label maker request init at #{Time.current}************************************************************************"
  #     request = RestClient::Request.new(:method => :post, :url => "#{ENV['LABELS_PORTAL_URL']}/process.php", :payload => {:multipart => true, :file => File.new(Rails.root.join('app/assets/csvs/file.csv'), 'rb')})
  #     # begin
  #       response = request.execute
  #       puts "**************************************Label maker request executed at #{Time.current}************************************************************************"
  #       labels_save_path = Rails.root.join('public','ordersummary', uniq_time_stamp + '.docx')
  #       File.open(labels_save_path, 'wb') do |file|
  #         file << open("#{ENV['LABELS_PORTAL_URL']}/#{response.body}").read
  #       end
  #       bucket_name = ENV['S3_BUCKET_NAME']
  #       key = "summarylabels/#{uniq_time_stamp}.docx"
  #       # S3UploadJob.perform_later(label_url_key, bucket_name, uniq_time_stamp, "label")
  #       label_url_key = EmailLog.upload_to_s3(key, bucket_name, uniq_time_stamp, "label")
        
  #       # label_url_key = @s3_label_obj.public_url.present? ? @s3_label_obj.key : nil

  #     # rescue StandardError => e
  #     #   label_url_key = nil
  #     #   puts "Labels Doc failed for runningmenu #{runningmenu.id} and address #{address.id} due to #{e.message}"
  #     # end
  #   else
  #     label_url_key = nil
  #   end

  #   puts "Label maker At #{admin} Cutoff start for address #{address.id} - #{Time.current}"
  #   puts "Label maker At #{admin} Cutoff found #{changed_active_orders.count}  active orders of quantity sum: #{changed_active_orders.sum{|o| o.quantity} } for address #{address.id} - #{Time.current}"
  #   if allLabelsOrders.any? && !runningmenu.buffet?
  #     uniq_time_stamp = "#{Time.current.to_i.to_s}_#{runningmenu.id}_#{address_runningmenu.id}"
  #     EmailLog.generate_labels_csv(runningmenu, allLabelsOrders)
  #     puts "**************************************Label maker request init at #{Time.current}************************************************************************"
  #     request = RestClient::Request.new(:method => :post, :url => "#{ENV['LABELS_PORTAL_URL']}/process.php", :payload => {:multipart => true, :file => File.new(Rails.root.join('app/assets/csvs/file.csv'), 'rb')})
  #     # begin
  #       response = request.execute
  #       puts "**************************************Label maker request executed at #{Time.current}************************************************************************"
  #       all_labels_save_path = Rails.root.join('public','ordersummary', uniq_time_stamp + '.docx')
  #       File.open(all_labels_save_path, 'wb') do |file|
  #         file << open("#{ENV['LABELS_PORTAL_URL']}/#{response.body}").read
  #       end

  #       bucket_name = ENV['S3_BUCKET_NAME']
  #       key = "summarylabels/#{uniq_time_stamp}.docx"
  #       # S3UploadJob.perform_later(all_labels_url_key, bucket_name, uniq_time_stamp, "label")
  #       all_labels_url_key = EmailLog.upload_to_s3(key, bucket_name, uniq_time_stamp, "label")
  #       address_runningmenu.update(summary_labels: all_labels_url_key)


  #     # rescue StandardError => e
  #     #   puts "Labels Doc failed for runningmenu #{runningmenu.id} and address #{address.id} due to #{e.message}"
  #     # end
  #   end
  #   puts "Label maker At #{admin} Cutoff end for address #{address.id} - #{Time.current}"
  #   # summary labels url end
  #   # begin
  #     if runningmenu.buffet?
  #       label_summary_contacts = nil
  #       summary_contacts = address.buffet_summary_contacts
  #     else
  #       label_summary_contacts = address.label_summary_contacts
  #       summary_contacts = address.summary_contacts
  #     end
  #     if label_summary_contacts.present?
  #       cc_contacts = label_summary_contacts.drop(1)
  #       puts "Found #{label_summary_contacts.count} contacts for address #{address.id} and scheduler #{runningmenu.id} - #{Time.current}"
  #       email = ScheduleMailer.changes_to_restaurant(runningmenu, changed_orders, address, label_summary_contacts.first, file_name, cc_contacts, before_cutoff_orders, admin.blank? ? 'Reminder:' : 'Updated')
  #       email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #       email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: pdf_url_key) if pdf_url_key.present?
  #       email_log.logs_attachments.new(attachment_file_name: file_name + '.docx', attachment: label_url_key) if label_url_key.present?
  #       email_log.save
  #     end
  #     if summary_contacts.present?
  #       cc_contacts = summary_contacts.drop(1)
  #       puts "Found #{summary_contacts.count} contacts for address #{address.id} and scheduler #{runningmenu.id} - #{Time.current}"
  #       email = ScheduleMailer.changes_to_restaurant(runningmenu, changed_orders, address, summary_contacts.first, file_name, cc_contacts, before_cutoff_orders, admin.blank? ? 'Reminder:' : 'Updated')
  #       email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #       email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: pdf_url_key) if pdf_url_key.present?
  #       email_log.save
  #     end
  #     unless address.contacts.present?
  #       puts "No contacts Found for address #{address.id} and scheduler #{runningmenu.id} email will go to order email- #{Time.current}"
  #       email = ScheduleMailer.changes_to_restaurant(runningmenu, changed_orders, address, nil, file_name, [], before_cutoff_orders, admin.blank? ? 'Reminder:' : 'Updated')
  #       email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #       email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: pdf_url_key) if pdf_url_key.present?
  #       email_log.logs_attachments.new(attachment_file_name: file_name + '.docx', attachment: label_url_key) if label_url_key.present?
  #       email_log.save
  #     end

  #   # rescue StandardError => e
  #   #   puts "Changes_to_restaurant failed due to: #{e.message} - #{Time.current}"
  #   # end
  # end
end
