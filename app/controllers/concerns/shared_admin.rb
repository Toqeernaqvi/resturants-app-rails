module SharedAdmin
  extend ActiveSupport::Concern

  included do
    helper_method :save_forwarded_email
  end

  def save_forwarded_email
    @invoice = Invoice.find_by_id params[:invoice_id]
    uniq_time_stamp = Time.current.to_i.to_s
    file_name = "Chowmill-#{@invoice.charged_cc ? 'Receipt' : 'Invoice'}-#{@invoice.shipping}-#{@invoice.invoice_number}".gsub!('/','-')
    pdf = render_to_string(pdf: file_name, template: 'admin/invoices/invoice.html.erb', :formats => [:html], :layout => false, :locals => {:invoice => @invoice}, margin: {
          top: 50,
          bottom: 5
      }, header: { html: {template: 'admin/invoices/invoice_header'} })
    FileUtils.mkdir_p 'public/download_pdfs'
    save_path = Rails.root.join('public/download_pdfs', file_name + '.pdf')
    File.open(save_path, 'wb') do |file|
      file << pdf
    end
    s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
    bucket_name = ENV['S3_BUCKET_NAME']
    @key = "invoicepdf/#{file_name}.pdf"
    @s3_obj = s3.bucket(bucket_name).object(@key)
    File.open(save_path, 'rb') do |file|
      @s3_obj.put(body: file, acl: 'public-read')
    end
    pdf_url_key = @s3_obj.key
    if params[:invoice][:recipients].present?
      if (params[:invoice][:recipients]).split(",").count > 1
        (params[:invoice][:recipients])&.split(",").each do |recipient|
          email_log = EmailLog.new(sender: params[:invoice][:sender], cc: params[:invoice][:cc], subject: params[:invoice][:subject], recipient: recipient, body: Base64.encode64(params[:invoice][:mail_body]))
          email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: pdf_url_key)
          email_log.save!
        end
      else
        email_log = EmailLog.new(sender: params[:invoice][:sender], cc: params[:invoice][:cc], subject: params[:invoice][:subject], recipient: params[:invoice][:recipients], body: Base64.encode64(params[:invoice][:mail_body]))
        email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: pdf_url_key)
        email_log.save!
      end
    end
    @invoice.update_attribute(:status, Invoice.statuses[:sent]) unless @invoice.paid?
    File.delete(save_path) if File.exist?(save_path)
  end
end