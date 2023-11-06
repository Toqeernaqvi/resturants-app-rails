ActiveAdmin.register Faxlog, as: 'Fax Log' do

  menu parent: 'Logs'
  config.batch_actions = false
  actions :all, :except => [:new, :create, :destroy ]

  index do
    column :from
    column :to
    column "Sent at" do |f|
      f.created_at.strftime('%a. %b %d %l:%M%P')
    end
    column "Resent" do |f|
      true if f.resent?
    end
    column "Attachment" do |f|
      link_to f.file_name, ENV["CLOUDFRONT_URL"]+"/"+f.media_url, target: "_blank" if f.media_url.present?
    end
    actions defaults: false do |fax_log|
      # item("Forward", resend_fax_admin_fax_log_path(fax_log.id), class: [:member_link, :forwardEmailBtn])
    end
  end

  # member_action :resend_fax, method: :get do
  #   faxlog = Faxlog.find params[:id]
  #   # @client = Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
  #   begin
  #     if Rails.env.production?
  #       fax = $twilio_client.fax.faxes.create(from: faxlog.from,to: faxlog.to, media_url: ENV["S3_BUCKET_URL"]+"/"+faxlog.media_url)
  #       Faxlog.create(from: fax.from, to: fax.to, sid: fax.sid, media_url: faxlog.media_url, status: Faxlog.statuses["resent"], file_name: faxlog.file_name)
  #     end
  #     redirect_to admin_fax_logs_path, notice: "Fax resent successfully."
  #   rescue StandardError => e
  #     redirect_to admin_fax_logs_path, alert: "Resending fax failed due to #{e.message}"
  #   end
  # end

  filter :from
  filter :to
  filter :created_at, label: "sent at", as: :date_range

  # controller do
  #   skip_before_action :verify_authenticity_token, only: [:resend_fax]
  # end

end
