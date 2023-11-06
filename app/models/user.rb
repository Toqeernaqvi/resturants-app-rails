class User < ApplicationRecord
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :trackable, :validatable,
          :confirmable,
          :lockable#, :omniauthable
  include DeviseTokenAuth::Concerns::User
  include Stripeable
  after_commit :send_pending_devise_notifications
  #acts_as_paranoid
  acts_as_ordered_taggable
  acts_as_taggable_tenant :company_id
  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  attr_accessor :notification_label
  attr_accessor :delete_stripe_card
  validates :time_zone, presence: true
  validates_format_of :phone_number,
  :with => /\A[0-9]{3}-[0-9]{3}-[0-9]{4}\Z/,
  :message => "- Phone numbers must be in xxx-xxx-xxxx format.", if: lambda{|u| u.company_admin? }
  belongs_to :company, optional: true
  belongs_to :address, optional: true
  belongs_to :office_admin, class_name: "User", optional: true

  has_many :orders, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :staffs, class_name: "User", foreign_key: "office_admin", dependent: :destroy

  has_many :cuisines_users, dependent: :destroy
  has_many :cuisines, through: :cuisines_users
  accepts_nested_attributes_for :cuisines_users, allow_destroy: true

  has_many :dietaries_users, dependent: :destroy
  has_many :dietaries, through: :dietaries_users
  accepts_nested_attributes_for :dietaries_users, allow_destroy: true

  has_many :addresses_vendor, dependent: :destroy
  has_many :addresses, through: :addresses_vendor
  accepts_nested_attributes_for :addresses_vendor, allow_destroy: true
  has_and_belongs_to_many :reports, dependent: :destroy
  has_many :payment_logs, dependent: :destroy
  has_many :favorite_fooditems, -> { where(favoritable_type: "Fooditem")}, class_name: 'Favorite'

  enum user_type: [:admin, :company_admin, :company_user, :restaurant_admin, :operations, :developer, :company_manager, :unsubsidized_user]
  enum profile_completed: [:no, :yes], _prefix: :profile_completed
  enum first_time: [:no, :yes], _prefix: :first_time
  enum status: [:active, :deleted]
  enum parent_status: [:active, :deleted], _prefix: :parent_status

  before_validation :set_provider
  before_validation :set_uid

  validates :office_admin_id, presence: true, if: lambda{|u| u.company_user? || u.unsubsidized_user? || u.company_manager? }
  validates_uniqueness_of :email

  # after_save :change_office_id, if: lambda{|u| u.user_type_changed? && u.company_admin? && u.user_type_was == 'company_user' }
  after_create :force_mail_confirmation
  after_save :after_save_user

  def after_save_user
    change_office_id if self.user_type_changed? && self.company_admin? && (self.user_type_was == 'company_user' || self.user_type_was == 'unsubsidized_user' || self.user_type_was == 'company_manager' )
    # create_customer if self.stripe_token.present? && self.stripe_token_changed?
  end

  def send_confirmation_instructions
    unless @raw_confirmation_token
      generate_confirmation_token!
    end

    opts = pending_reconfirmation? ? { to: unconfirmed_email } : { }
    send_devise_notification(:confirmation_instructions, @raw_confirmation_token, opts)
  end

  # override devise method to include additional info as opts hash
  def send_reset_password_instructions(opts = {})
    if reset_password_period_valid? && reset_password_raw_token != reset_password_token
      token = reset_password_raw_token.present? ? reset_password_raw_token : set_reset_password_token
    else
      token = set_reset_password_token
    end

    # fall back to "default" config name
    opts[:client_config] ||= 'default'

    send_devise_notification(:reset_password_instructions, token, opts)
    self.update_columns(reset_password_raw_token: token)
    token
  end

  def change_office_id
    self.update_column(:office_admin_id, nil)
  end

  def send_pending_devise_notifications
    pending_devise_notifications.each do |notification, args|
      render_and_send_devise_message(notification, *args)
    end
    pending_devise_notifications.clear
  end

  def send_devise_notification(notification, *args)
    if new_record? || changed?
      pending_devise_notifications << [notification, args]
    else
      render_and_send_devise_message(notification, *args)
    end
  end

  def pending_devise_notifications
    @pending_devise_notifications ||= []
  end

  def render_and_send_devise_message(notification, *args)
    email = devise_mailer.send(notification, self, *args)
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  end

  def force_mail_confirmation
    self.send_confirmation_instructions
  end

  def set_provider
    self[:provider] = "email" if self[:provider].blank?
  end

  def set_uid
    self[:uid] = self[:email] if self[:uid].blank? && self[:email].present?
  end

  def name
    if first_name.present? || last_name.present?
      first_name.to_s + ' ' + last_name.to_s
    else
      email
    end
  end

  def current_company_address_cords
    if !self.address_id.nil? && !self.company_id.nil?
      company_address = self.company.addresses.find self.address_id
      [company_address.latitude, company_address.longitude]
    else
      []
    end
  end

  # def create_customer
  #   begin
  #     customer = Stripe::Customer.create({
  #       name: self.name,
  #       email: self.email,
  #       description: "Customer for #{self.company.name}",
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

  def customer
    if (self.company.present? && self.company.user_copay > 0) && (self.company_user? || self.company_manager?) && self.profile_completed? && self.customer_id.blank?
     false
    else
      true
    end
  end

  def quickbooks_identity(setting, access_token)
    begin
      service = Quickbooks::Service::Customer.new
      service.company_id = setting.realmid
      service.access_token = access_token
      # customer = service.find_by(:given_name, self.name)
      util = Quickbooks::Util::QueryBuilder.new
      clause1 = util.clause("GivenName", "=", self.name.strip)
      clause2 = util.clause("DisplayName", "=", self.name.strip)
      customer = service.query("SELECT * FROM Customer WHERE #{clause1}")
      customer = service.query("SELECT * FROM Customer WHERE #{clause2}") unless customer.first.present?
      if customer.first.present?
        return customer.first.id
      else
        customer = Quickbooks::Model::Customer.new
        customer.first_name = self.first_name
        customer.last_name = self.last_name
        customer.given_name = self.name
        customer.middle_name = self.name+self.id.to_s
        customer.display_name = self.name
        customer.email = self.email
        customer.company_name = self.company.name
        created_customer = service.create(customer)
        puts "###################################################### Created Customer id is: "+created_customer.id.to_s
        return created_customer.id
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
    end
  end

  # def client_token
  #   $gateway.client_token.generate(:customer_id => self.customer_id) rescue nil
  # end

  # def self.calculate_pendingtotal
  #   puts "Pending Total Start"
  #   begin
  #     users = User.where(id: Order.active.pending.where("process = #{Order.processes['no']} AND user_price > ?", 0).joins(runningmenu: [:company]).where("TO_CHAR(now() AT TIME ZONE companies.time_zone, 'HHam') = '02pm' AND runningmenus.status = #{Runningmenu.statuses['approved']} AND runningmenus.delivery_at < ?", Time.current).where(share_meeting_id: nil).pluck(:user_id))
  #     users.each do |user|
  #       puts "Pending Total: In a loop user id #{user.id}"
  #       orders = user.orders.active.pending.where("process = #{Order.processes['no']} AND user_price > ?", 0).joins(runningmenu: [:company]).where("TO_CHAR(now() AT TIME ZONE companies.time_zone, 'HHam') = '02pm' AND runningmenus.status = #{Runningmenu.statuses['approved']} AND runningmenus.delivery_at < ?", Time.current).where(share_meeting_id: nil)
  #       pendingtotal = orders.sum{|o| o.user_markup ? (o.user_price+o.site_price) : o.user_price }
  #       user.pending_total += pendingtotal
  #       if user.save
  #         puts "Pending Total: User #{user.id} pending total updated"
  #         unless orders.update_all(process: Order.processes['yes'])
  #           user.pendingtotal -= pendingtotal
  #           user.save
  #         end
  #       else
  #         puts "Pending Total: User #{user.id} pending total update failed"
  #       end
  #     end
  #   rescue StandardError => e
  #      puts "Pending Total: #{e}"
  #   end
  #   puts "Pending Total End"
  # end

  def time_zone_offset
    ActiveSupport::TimeZone.new(self.time_zone).utc_offset / 3600 rescue nil
  end

  def as_json(options = nil)
    super({ only: [
      :id,
      :stripe_user_id,
      :first_name,
      :last_name,
      :email,
      :office_admin_id,
      :address_id,
      :phone_number,
      :allow_admin_to_manage_users,
      :sms_notification,
      :user_type,
      :survey_mail,
      :cutoff_hour_lunch_reminder,
      :admin_cutoff_hour_lunch_reminder,
      :cutoff_hour_dinner_reminder,
      :admin_cutoff_hour_dinner_reminder,
      :cutoff_hour_breakfast_reminder,
      :admin_cutoff_hour_breakfast_reminder,
      :cutoff_day_lunch_reminder,
      :admin_cutoff_day_lunch_reminder,
      :cutoff_day_dinner_reminder,
      :admin_cutoff_day_dinner_reminder,
      :cutoff_day_breakfast_reminder,
      :admin_cutoff_day_breakfast_reminder,
      :menu_ready_email,
      :time_zone,
      :tag_list,
    ], methods: [:time_zone_offset, :name, :customer] }.merge(options || {}))
  end

  ransacker :rest, formatter: proc {|value|
    results = RestaurantAdmin.joins(:addresses_vendor => :address).where("addresses.addressable_id = ?", value.to_i).pluck(:id)
    results = results.present? ? results.uniq : nil
  } do |parent|
    parent.table[:id]
  end

  ransacker :status, formatter: proc {|value|
    if value == "invited"
      results = User.active.where.not(:profile_completed=>"yes").pluck(:id)
    else
      results = value.to_i == 0 ? User.active.where(:profile_completed=>"yes").pluck(:id) : User.deleted.pluck(:id)
    end
    results = results.present? ? results.uniq : nil
  } do |parent|
    parent.table[:id]
  end

  protected
    def password_required?
      confirmed? ? super : false
    end
end
