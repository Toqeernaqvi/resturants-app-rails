class AddressesRunningmenu < ApplicationRecord
  default_scope -> {order(rank: :asc)}
  belongs_to :runningmenu
  belongs_to :address
  belongs_to :dynamic_section, optional: true
  enum acknowledge_receipt: [:declined, :acknowledge], _prefix: :receipt
  enum accept_orders: [:declined, :acknowledge], _prefix: :orders
  enum accept_changes: [:declined, :acknowledge], _prefix: :changes
  enum pre_week_email: [:not_sent, :sent], _prefix: :pre_week_email
  enum pre_email: [:not_sent, :sent], _prefix: :pre_email
  enum task_status: [:not_created, :created, :started, :arrived, :completed]
  enum before_pickup_job_status: [:pending, :processed, :not_processed], _prefix: 'before_pickup_job'
  attr_accessor :message
  before_destroy :send_no_changes_email
  before_save :set_order
  after_create :check_orders
  after_save :send_status_email#, if: lambda { |a| a.saved_change_to_accept_orders? && a.orders_acknowledge? }
  
  def check_orders
    if self.runningmenu.orders.active.present? && self.runningmenu.delivery?
      self.destroy if self.runningmenu.orders.active.last.restaurant_address_id != self.address_id
    end
  end

  def set_order
    rank = AddressesRunningmenu.where(runningmenu_id: self.runningmenu_id).maximum(:rank)
    address_runningmenu = AddressesRunningmenu.where(runningmenu_id: self.runningmenu_id).order(rank: :desc).last
    if rank.present? && address_runningmenu.present? && address_runningmenu.address.addressable.name == ENV['BEV_AND_MORE']
      address_runningmenu.update_column(:rank, rank + 1)
      self.rank = rank
    else
      self.rank = (rank.present? ? rank : 0) + 1
    end
  end

  def send_no_changes_email
    if self.runningmenu.orders.active.where(restaurant_address_id: self.address.id).present?
      self.runningmenu.restaurant_deleted = true
      self.runningmenu.deleted_restaurant_name = self.address.addressable.name
      throw :abort
    elsif self.pre_week_email_sent?
      summary_contacts = self.address.summary_contacts
      cc_contacts = summary_contacts.drop(1)
      contact = summary_contacts.first
      if contact.present?
        email = ScheduleMailer.no_changes(self.runningmenu, contact, self.address, cc_contacts)
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      end
    end
  end

  def send_status_email
    orders_status = nil
    if self.saved_change_to_accept_orders? && self.orders_acknowledge?
      orders_status = true
    elsif self.saved_change_to_rejected_by_vendor? && self.rejected_by_vendor
      orders_status = false
      self.message = self.reject_reason
    end
    unless orders_status.nil?
      email = ScheduleMailer.orders_status(self.runningmenu, self.address, orders_status, self.message)
      EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
    end
  end

  def set_before_pickup_job
    items = self.runningmenu.orders.active.where(restaurant_address_id: self.address_id).sum(:quantity)
    return if items < 1
    if self.before_pickup_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.before_pickup_job_id)
      job.delete unless job.nil?
    end
    job_id = BeforePickupWorker.perform_at(self.runningmenu.pickup_at_timezone.utc, self.id)
    self.update_columns(before_pickup_job_id: job_id)
  end

end
