class PaymentLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :company, optional: true
  has_and_belongs_to_many :orders

  enum payment_gateway: [:braintree, :stripe]
  enum status: [:success, :failed, :refunded]
  attr_accessor :invoice_number

  validates :refund_amount, numericality: { greater_than: 0 }
  validates :refund_amount, numericality: { less_than_or_equal_to: :amount }
  # after_create_commit :generate_sales_receipt, if: lambda {|obj| obj.orders.active.where("user_paid > 0").present? && obj.success? }

  def generate_sales_receipt
    UploadSalesReceiptToQuickbookJob.perform_later(self.id)
  end

  def inform_finance(message)
    email = WebhookMailer.quickbook_error(message, self.id, "PaymentLog")
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  end

end
