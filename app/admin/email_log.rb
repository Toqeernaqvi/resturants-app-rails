ActiveAdmin.register EmailLog, as: 'Email Log' do
  #menu priority: 9
  menu parent: 'Logs'
  config.batch_actions = false
  actions :all, :except => [:new, :create, :destroy ]

  permit_params do
    permitted = [:sender, :recipient, :subject, :body, :sent_at, :cc]
  end

  index do
    column :id
    column :sender
    column :recipient
    column :subject
    column :cc
    column :body do |e|
      ActionView::Base.full_sanitizer.sanitize(Base64.decode64(e.body)).truncate_words(10)
    end
    column "Attachment" do |e|
      e.logs_attachments.map {|attached_file| link_to attached_file.attachment_file_name&.encode("ASCII", "UTF-8", invalid: :replace, undef: :replace, replace: ""), (attached_file.attachment&.include?(ENV["BACKEND_HOST"]) ? "" : ENV["CLOUDFRONT_URL"]) +"/"+ attached_file.attachment if  attached_file.attachment_file_name.present? }.join(', </br>').html_safe
    end
    column :sent_at
    column :failed_at
    column :status do |email|
      # if email.pending?
      #   status_tag( :pending )
      # elsif email.sent?
      #   status_tag( :sent )
      # elsif email.cancelled?
      #   status_tag( :cancelled )
      # else
      #   status_tag( :failed )
      # end
      status_tag( email.status.to_sym )
    end
    actions defaults: false do |email_log|
      item 'View', admin_email_log_path(email_log), class: :member_link
      if email_log.pending?
        item 'Edit', edit_admin_email_log_path(email_log), class: :member_link
        item('Cancel', cancel_admin_email_log_path(email_log.id), class: :member_link)
      end
      item("Forward", forward_email_admin_email_log_path(email_log.id), remote: true, class: [:member_link, :forwardEmailBtn])
    end
  end

  csv do
    column :id
    column :sender
    column :recipient
    column :subject
    column :cc
    column :sent_at
    column :failed_at
    column :status
  end

  form do |f|
    f.inputs do
      f.input :sender
      f.input :recipient
      f.input :subject
      f.input :body, input_html: { value: Base64.decode64(f.object.body)}
    end
    f.actions do
      f.action(:submit)
      f.cancel_link
    end
  end

  show do
    attributes_table do
      row :id
      row :sender
      row :recipient
      row :cc
      row :subject do |e|
        e.subject.encode("ASCII", "UTF-8", invalid: :replace, undef: :replace, replace: "")
      end
      row "Attachment" do |e|
        e.logs_attachments.map {|attached_file| link_to attached_file.attachment_file_name.encode("ASCII", "UTF-8", invalid: :replace, undef: :replace, replace: ""), ENV["CLOUDFRONT_URL"]+"/"+attached_file.attachment}.join(', </br>').html_safe
      end
      row :body do |e|
        Base64.decode64(e.body).html_safe
      end
      row :sent_at
      row :failed_at
      row :status do |email|
        if email.pending?
          status_tag( :pending )
        elsif email.sent?
          status_tag( :sent )
        elsif email.cancelled?
          status_tag( :cancelled )
        else
          status_tag( :failed )
        end
      end
    end
  end

  member_action :cancel, method: :get do
    email_log = EmailLog.find(params[:id])
    email_log.cancelled!
    redirect_to admin_email_logs_path, notice: "Email has been successfully cancelled"
  end

  member_action :download_pdf, method: :get do
    email_log = EmailLog.find(params[:id])
    pdf = File.read("#{Rails.root}/public/download_pdfs/#{email_log.attachment_file_name}")
    send_data pdf, filename: email_log.attachment_file_name
  end

  member_action :forward_email, method: :get do
    @email_log = EmailLog.find(params[:id])
    respond_to do |format|
      format.js { render "forward_email" }
    end
  end

  member_action :download_email_body, method: :get do
    if params[:id].present?
      email_log = EmailLog.find_by_id(params[:id])
      pdf = WickedPdf.new.pdf_from_string(Base64.decode64(email_log.body.to_s.force_encoding("UTF-8")))
      send_data pdf, filename: "Email Body #{email_log.id}", :disposition => 'inline', :type => "application/pdf", :target => '_blank'
    end
  end

  collection_action :forwarded_email, method: :post do
    email_log = EmailLog.find_by_id params[:email_log_id]
    multiFileSelected_arr = params[:multiFileSelected].split(',')
    if params[:email_log].present? && params[:email_log][:attachment_file_name].present?
      uploaded = true
      forward_email = EmailLog.new(sender: params[:email_log][:sender], subject: params[:email_log][:subject], recipient: params[:email_log][:recipient], cc: params[:email_log][:cc], body: Base64.encode64(params[:email_log][:mail_body]), status: :pending)
      params[:email_log][:attachment_file_name].each_with_index do |file, index|
        if multiFileSelected_arr.include?(index.to_s)
          pdf = file.read
          FileUtils.mkdir_p 'public/download_pdfs'
          save_path = Rails.root.join('public/download_pdfs', file.original_filename)
          File.open(save_path, 'wb') do |file|
            file << pdf
          end

          s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
          bucket_name = ENV['S3_BUCKET_NAME']
          @key = "summarypdf/#{file.original_filename}"
          @s3_obj = s3.bucket(bucket_name).object(@key)
          File.open(save_path, 'rb') do |file|
            uploaded = @s3_obj.put(body: file, acl: 'public-read') rescue false
          end
          forward_email.logs_attachments.new(attachment: @s3_obj.key, attachment_file_name: file.original_filename) if uploaded
        end
      end
      if params[:fileSelected].present?
        params[:fileSelected].split(',').each do |f|
          forward_email.logs_attachments.new(attachment: LogsAttachment.find(f.to_i).attachment, attachment_file_name: LogsAttachment.find(f.to_i).attachment_file_name)
        end
      end
      forward_email.save!
    elsif params[:fileSelected].present?
      forward_email = EmailLog.new(sender: params[:email_log][:sender], subject: params[:email_log][:subject], recipient: params[:email_log][:recipient], cc: params[:email_log][:cc], body: Base64.encode64(params[:email_log][:mail_body]), status: :pending)
      params[:fileSelected].split(',').each do |f|
        forward_email.logs_attachments.new(attachment: LogsAttachment.find(f.to_i).attachment, attachment_file_name: LogsAttachment.find(f.to_i).attachment_file_name)
      end
      forward_email.save!
    else
      EmailLog.create(sender: params[:email_log][:sender], subject: params[:email_log][:subject], recipient: params[:email_log][:recipient], body: Base64.encode64(params[:email_log][:mail_body]), status: :pending, cc: params[:email_log][:cc])
    end
    flash[:notice] = "Email forwarded successfully."
    redirect_to admin_email_logs_path
  end

  filter :sender
  filter :recipient
  filter :subject, :input_html => { :disabled => true } 
  filter :sent_at, as: :date_range

  controller do
    skip_before_action :verify_authenticity_token, only: [:forwarded_email]
    def scoped_collection
      super.includes :logs_attachments
    end
  end
end
