class UploadToQuickbookJob < ApplicationJob
  queue_as :upload_to_quickbook

  def perform(invoice_ids)
    setting = Setting.latest
    access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
    Invoice.where(id: invoice_ids).each do |invoice|
      puts "Invoice Number #{invoice.invoice_number} start uploading to quickbook"
      invoice.upload_to_quickbook(invoice.id, setting, access_token)
      puts "Invoice Number #{invoice.invoice_number} end uploading to quickbook"
    end
  end

end
