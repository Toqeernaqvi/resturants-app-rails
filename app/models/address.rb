class Address < ApplicationRecord
  #acts_as_paranoid

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  scope :newest, -> { order(created_at: :desc).first }
  scope :oldest, -> { order(created_at: :asc).first }

  belongs_to :lunch_sequence, class_name: 'Sequence', optional: true
  belongs_to :dinner_sequence, class_name: 'Sequence', optional: true
  belongs_to :breakfast_sequence, class_name: 'Sequence', optional: true
  belongs_to :buffet_sequence, class_name: 'Sequence', optional: true
  belongs_to :default_admin, class_name: 'CompanyAdmin', foreign_key: 'user_id', optional: true
  has_many :companies_schedules
  belongs_to :addressable, optional: true, :polymorphic => true
  has_many :addresses_vendor
  has_many :addresses, through: :addresses_vendor
  has_many :ratings, foreign_key: :restaurant_address_id
  has_many :admins, through: :addresses_vendor, source: :user
  has_many :holidays
  has_many :restaurant_billings
  has_many :contacts
  has_many :menus
  has_one :menu_breakfast
  has_one :menu_lunch
  has_one :menu_dinner
  has_one :menu_buffet
  has_many :addresses_runningmenus
  has_many :runningmenus, through: :addresses_runningmenus
  has_many :restaurant_shifts
  has_many :monday_shifts, class_name: "RestaurantMondayShift"
  has_many :tuesday_shifts, class_name: "RestaurantTuesdayShift"
  has_many :wednesday_shifts, class_name: "RestaurantWednesdayShift"
  has_many :thursday_shifts, class_name: "RestaurantThursdayShift"
  has_many :friday_shifts, class_name: "RestaurantFridayShift"
  has_many :saturday_shifts, class_name: "RestaurantSaturdayShift"
  has_many :sunday_shifts, class_name: "RestaurantSundayShift"
  has_many :dishsizes
  mount_uploader :logo, FooditemUploader
  has_many :images, as: :imageable
  accepts_nested_attributes_for :images, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :dishsizes, :allow_destroy => true
  accepts_nested_attributes_for :monday_shifts, :tuesday_shifts, :wednesday_shifts, :thursday_shifts, :friday_shifts, :saturday_shifts, :sunday_shifts, allow_destroy: true
  accepts_nested_attributes_for :addresses_vendor, allow_destroy: true
  accepts_nested_attributes_for :contacts, :holidays, reject_if: :all_blank, allow_destroy: true

  validates :name, :address_line, :buffet_price, presence: true
  validates_format_of :city, :state, with: /^[A-Za-z\s-]+$/ , multiline: true, :message => 'must be a string', allow_blank: true, if: lambda { |a| ["Billing","Approver"].include? a.addressable_type}
  validates :zip, numericality: {greater_than_or_equal_to: 0, message: "must be a number"}, allow_blank: true, if: lambda { |a| ["Billing","Approver"].include? a.addressable_type}
  validates :lunch_order_capacity, :dinner_order_capacity, numericality: {greater_than_or_equal_to: 0 }, unless: lambda { |a| a.saved_change_to_status?}
  validates :discount_percentage, numericality: {greater_than_or_equal_to: 0}
  validate :latitude_longitude, if: lambda { |a| !(["Billing","Approver"].include? a.addressable_type) && a.will_save_change_to_address_line? && !a.will_save_change_to_status? && !a.will_save_change_to_parent_status?}
  validates :delayed_payout_days, numericality: {greater_than_or_equal_to: 6}, if: lambda {|a| a.addressable_type == "Restaurant" && !a.will_save_change_to_status? && !a.will_save_change_to_parent_status?}
  validates :items_count, numericality: { greater_than_or_equal_to: 0}, if: lambda {|a| a.will_save_change_to_items_count?}
  validates :buffet_commission, numericality: { greater_than_or_equal_to: 0}, if: lambda {|a| a.will_save_change_to_buffet_commission?}
  validates :minimum_discount_price, numericality: { greater_than_or_equal_to: 0}, if: lambda {|a| a.will_save_change_to_minimum_discount_price?}
  validates :individual_meals_cutoff, :buffet_cutoff, numericality: { greater_than_or_equal_to: 0 }
  enum status: [:active, :deleted]

  validate :validate_images, if: lambda { |a| a.enable_marketplace }
  validate :check_running_meetings, if: lambda {|a| a.addressable_type == "Company" && a.will_save_change_to_parent_status? && a.parent_status_deleted? }
  validates :delivery_radius, :delivery_cost, :minimum_order_quantity, numericality: { greater_than_or_equal_to: 0 }, if: lambda { |a| a.enable_self_service }
  geocoded_by :address_line
  after_validation :geocode, :if => :address_line_changed?

  enum parent_status: [:active, :deleted], _prefix: :parent_status
  after_save :update_status, if: lambda{|a| a.saved_change_to_parent_status?}
  after_save :update_menus, if: lambda{|a| a.saved_change_to_status? && a.menus.present?}
  after_save :update_order_restaurant_payout_calculation, if: lambda { |a| a.addressable_type == "Restaurant" && (a.saved_change_to_discount_percentage? || a.saved_change_to_add_contract_commission? || a.saved_change_to_buffet_commission? || a.saved_change_to_zip?)}
  after_update :set_billing_days, if: lambda{|a| a.saved_change_to_delayed_payout_days?}
  after_commit :reindex_restaurant_address, if: lambda { |a| a.addressable_type == "Restaurant"}

  attr_accessor :updated_from_frontend

  def check_running_meetings
    if Runningmenu.approved.where("address_id = ? AND delivery_at > ?", self.id, Time.current.in_time_zone(self.addressable.time_zone)).exists?
      errors.add(:address_line, "This address is in use of active meeting")
    end
  end

  def validate_images
    if !random_menu_images && images.size < 2
      errors.add(:images, " must be two or more.")
    end
  end

  def reindex_restaurant_address
    begin
      RestaurantAddressReindexJob.perform_later(self.id)
    rescue ArgumentError => e
      puts e
      return
    end  
  end

  def update_order_restaurant_payout_calculation
    begin
      RestaurantPayoutOrderCalculationJob.perform_later(self.id)
    rescue ArgumentError => e
      puts e
      return
    end
  end

  def latitude_longitude
    if (!self.will_save_change_to_longitude? && !self.will_save_change_to_latitude?) || (self.new_record? && self.longitude.blank? && self.latitude.blank?)
      errors.add(:address_line, "Please select correct address from suggestions.")
    end
  end

  def set_billing_days
    RestaurantBilling.where(address_id: self.id, payment_status: :final).each do |b|
      due_at = self.delayed_payout_days.days.since( b.orders.joins(:runningmenu).order("runningmenus.delivery_at desc").pluck("runningmenus.delivery_at").first.in_time_zone(b.restaurant.time_zone) )
      b.update(due_date: due_at)
    end
  end

  def update_status
    if self.parent_status_active?
      self.active!
      if self.addressable_type == "Company"
        Runningmenu.cancelled.where("address_id = ? AND delivery_at > ? AND status = ? AND parent_status != ? ", self.id, Time.current.in_time_zone(self.addressable.time_zone), Runningmenu.statuses[:cancelled], Runningmenu.statuses[:cancelled]).each do |runningmenu|
          runningmenu.update(status: Runningmenu.statuses[:pending])
        end
      end
    else
      self.deleted!
      if self.addressable_type == "Company"
        Runningmenu.pending.where("address_id = ? AND delivery_at > ?", self.id, Time.current.in_time_zone(self.addressable.time_zone)).each do |runningmenu|
          runningmenu.update(status: Runningmenu.statuses[:cancelled])
        end
      end
    end
    self.dishsizes.each do |dishsize|
      self.deleted? ? dishsize.deleted! : (dishsize.parent_status_deleted? ? dishsize.deleted! : dishsize.active!)
    end
  end

  def update_menus
    self.menus.each do |menu|
      if menu.active?
        menu.deleted!
      else
        menu.active!
      end
    end
  end

  # def invoice_pdf
  #   self.street_number.to_s + " " + self.street.to_s + ", " + self.city.to_s
  # end

  def name
    if self.addressable.present?
      self.addressable.name + ': ' + address_line
    else
      address_line
    end
  end

  def adress_name_format
    if self.addressable.present?
      self.addressable.name + ': ' + address_name + ': ' + address_line
    else
      address_line
    end
  end

  def location
    str = []
    str << [[self.street_number, self.street].join(' '), self.suite_no, self.city]
    str.flatten.compact.reject{|a| a == ""}.join(', ')
  end

  def location_with_name
    str = []
    str << [[self.street_number, self.street].join(' '), self.suite_no, self.address_name, self.city]
    str.flatten.compact.reject{|a| a == ""}.join(', ')
  end

  def formatted_address
    str = self.address_name.blank? ? "" : self.address_name + ": "
    str += [[self.street_number, self.street].compact.reject(&:empty?).join(' '), self.suite_no, self.city].compact.reject(&:empty?).join(", ")
  end

  def formatted_delivery_address
    str = self.address_name.blank? ? "" : self.address_name + ": "
    str += [[self.street_number, self.street].compact.reject(&:empty?).join(' '), self.suite_no].compact.reject(&:empty?).join(", ")
  end

  def medium_image_url
    self.image_url(:medium)
  end

  def contact_card
    contact = User.active.joins(:addresses_vendor).where(addresses_vendors: { address_id: self.id} ).order(primary_contact: :desc).first
    if contact.blank?
      contact = self.contacts.first
    end
    return contact
  end

  def contact_numbers
    arr = self.contacts.where("send_text_reminders = ? AND phone_number IS NOT NULL AND phone_number != ''", true).select("contacts.id, phone_number, name AS full_name") + self.admins.active.where("send_text_reminders = ? AND phone_number IS NOT NULL AND phone_number != '' ", true).select("users.id, phone_number, CONCAT(first_name, last_name) AS full_name")
    arr.map{|a| a.phone_number = ("+1"+a.phone_number.gsub("-","")) }
    arr
  end

  def summary_contacts
    summary_contacts = self.contacts.where(email_summary_check: true).pluck(:email)+self.admins.active.where(email_summary_check: true).pluck(:email)
    summary_contacts = summary_contacts.uniq
  end

  def summary_without_label_contacts
    summary_contacts = self.contacts.where(email_summary_check: true, email_label_check: false).pluck(:email)+self.admins.active.where(email_summary_check: true, email_label_check: false).pluck(:email)
    summary_contacts = summary_contacts.uniq
  end

  def label_summary_contacts
    summary_contacts = self.contacts.where(email_summary_check: true, email_label_check: true).pluck(:email)+self.admins.active.where(email_summary_check: true, email_label_check: true).pluck(:email)
    summary_contacts = summary_contacts.uniq
  end

  def fax_summary_contacts
    summary_contacts = self.contacts.where.not(fax: "", fax_summary_check: false).pluck(:fax)+self.admins.active.where.not(fax: "", fax_summary_check: false).pluck(:fax)
    summary_contacts = summary_contacts.uniq
  end

  def as_json(options = nil)
    super({ only: [:id, :address_name, :address_line, :street, :city, :state, :zip, :suite_no, :enable_marketplace, :delivery_instructions], methods: [:name, :location] }.merge(options || {}))
  end
end
