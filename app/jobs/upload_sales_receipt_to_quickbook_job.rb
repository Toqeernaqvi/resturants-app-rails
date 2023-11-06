class UploadSalesReceiptToQuickbookJob < ApplicationJob
  queue_as :upload_sales_receipt_to_quickbook

  def perform(payment_log_id)
    payment_log = PaymentLog.find(payment_log_id)
    begin
      setting = Setting.latest
      access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
      txn_date = payment_log.created_at
      orders = payment_log.orders.active.where("user_paid > 0")
      quantity = orders.sum(&:quantity).to_f
      total = orders.sum(&:user_paid)
      qb_unit_price = (total/quantity).round 4
      customer_id = payment_log.user.quickbooks_identity(setting, access_token)
      salesreceipt = Quickbooks::Model::SalesReceipt.new({
          customer_id: customer_id,
          txn_date: Date.civil(txn_date.year, txn_date.month, txn_date.day),
          payment_ref_number: payment_log.transaction_id
      })
      salesreceipt.doc_number = payment_log.id
      salesreceipt.currency_ref = Quickbooks::Model::BaseReference.new('USD')
      salesreceipt.customer_ref.name = payment_log.user&.company&.name&.strip
      line_item = Quickbooks::Model::Line.new
      line_item.amount = qb_unit_price*quantity
      line_item.description = "All fooditems charges except delivery fee"
      line_item.sales_item! do |detail|
          detail.unit_price = qb_unit_price.to_s
          detail.quantity = quantity
          detail.item_id = ENV["QB_ITEM"]
          detail.item_ref.name = payment_log.company&.name&.strip
          detail.service_date = payment_log.created_at
      end
      salesreceipt.line_items << line_item
      service = Quickbooks::Service::SalesReceipt.new
      service.company_id = setting.realmid
      service.access_token = access_token
      created_receipt = service.create(salesreceipt)
      QuickbookLog.create!(upload_identity: payment_log.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[2]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[0]], quickbook_identity: created_receipt.id)
      puts "###################################################### Created Receipt id is: "+created_receipt.id.to_s
    rescue StandardError => e
      puts "failed to upload sales receipt to quickbook #{payment_log.id}: #{e.message}"
      payment_log.inform_finance(e.message)
    end
  end
  
end
