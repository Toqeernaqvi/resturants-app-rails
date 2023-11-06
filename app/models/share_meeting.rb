class ShareMeeting < ApplicationRecord
  include Stripeable
  belongs_to :user
  belongs_to :runningmenu
  has_many :orders

  validates :emails, presence: true, unless: lambda { |m| m.email.present? }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, unless: lambda { |m| m.email.blank? }
  validates :email, uniqueness: { scope: :runningmenu }#, unless: lambda {|m| m.email.present?}

  before_create :generate_token
  after_create :send_invited_email, if: lambda{|s| s.emails.present?}
  # after_update :create_customer, if: lambda{|s| s.stripe_token_changed?}

  attr_accessor :emails, :delete_stripe_card

  def send_invited_email
    email = ScheduleMailer.share(self)
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  end

  def ordered
    self.orders.active.count
  end

  # def create_customer
  #   begin
  #     customer = Stripe::Customer.create({
  #       name: self.name,
  #       email: self.email,
  #       description: "Customer for ShareMeeting##{self.id}",
  #       source: self.stripe_token
  #     })
  #     if customer.present?
  #       self.update_columns(customer_id: customer.id)
  #     end
  #   rescue Stripe::CardError => e
  #     errors.add(:stripe_token, "Credit Card failed to save due to #{e.message}")
  #   rescue => e
  #     errors.add(:stripe_token, "Credit Card failed to save due to #{e.message}")
  #   end
  # end

  def name
    if first_name.present? || last_name.present?
      first_name.to_s + ' ' + last_name.to_s
    else
      email
    end
  end

  def as_json(options = nil)
    super({ only: [
      :id,
      :first_name,
      :last_name,
      :name,
      :email,
      :user_id,
      :runningmenu_id,
      :token,
    ], methods: [:ordered] }.merge(options || {}))
  end

  protected

  def self.parse_emails(emails)
    return if emails.blank?
    emails = emails.split(/[,\s<>]+/)
    emails = emails.select{|a| a.match?URI::MailTo::EMAIL_REGEXP }
  end

  def generate_token
    self.token = SecureRandom.urlsafe_base64
    generate_token if ShareMeeting.exists?(token: self.token)
  end
end
