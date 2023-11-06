class RecurringScheduler < ApplicationRecord
  has_paper_trail versions: { scope: -> { order("id desc") } }, if: lambda {|r| r.saved_change_to_user_id? || r.saved_change_to_company_id? || r.saved_change_to_address_id? || r.saved_change_to_driver_id? || r.saved_change_to_runningmenu_type? || r.saved_change_to_menu_type? || r.saved_change_to_status? || r.saved_change_to_parent_status? || r.saved_change_to_per_meal_budget? || r.saved_change_to_orders_count? || r.saved_change_to_per_user_copay? || r.saved_change_to_per_user_copay_amount? || r.saved_change_to_monday? || r.saved_change_to_tuesday? || r.saved_change_to_wednesday? || r.saved_change_to_thursday? || r.saved_change_to_friday? || r.saved_change_to_saturday? || r.saved_change_to_sunday? || r.saved_change_to_recurrence_days? || r.saved_change_to_startdate? || r.saved_change_to_delivery_instructions? || r.saved_change_to_hide_meeting?}
  
  acts_as_ordered_taggable
  acts_as_taggable_tenant :company_id

  belongs_to :user
  belongs_to :company, optional: true
  belongs_to :address
  belongs_to :driver, optional: true
  has_many :runningmenufields
  has_many :addresses_recurring_schedulers
  has_many :addresses, through: :addresses_recurring_schedulers, dependent: :destroy
  has_many :cuisines_recurring_menus, dependent: :destroy
  has_many :cuisines, through: :cuisines_recurring_menus
  has_many :recurring_dynamic_sections
  enum runningmenu_type: [:dont_care, :lunch, :dinner, :breakfast]
  enum status: [:approved, :pending, :cancelled]
  enum parent_status: [:active, :deleted], _prefix: :parent_status
  enum menu_type: [:individual, :buffet]
  attr_accessor :dynamic_sections_address_ids, :user_at_update, :skip_cuttoff_check, :selected_driver_id, :bev_rest_id, :restaurant_deleted, :deleted_restaurant_name, :script_errors
  accepts_nested_attributes_for :runningmenufields, allow_destroy: true
  accepts_nested_attributes_for :cuisines_recurring_menus, allow_destroy: true
  accepts_nested_attributes_for :recurring_dynamic_sections, allow_destroy: true

  before_save :add_company
  before_save :check_copay, if: lambda {|r| r.will_save_change_to_per_user_copay?}

  before_validation :check_cuisines_change, :set_startdate_as_utc

  validates :runningmenu_type, :runningmenu_name, :user_id, :startdate, :recurrence_days, presence: true
  validates :runningmenu_type, inclusion: { in: %w(lunch dinner breakfast), message: "Please select Lunch, Dinner or Breakfast of schedules." }
  validates_length_of :orders_count, in: 1..5
  validates :per_meal_budget, :orders_count, :per_user_copay_amount, :cutoff_hours, :cutoff_minutes, :admin_cutoff_hours, :admin_cutoff_minutes, :pickup_hours, :pickup_minutes,  numericality: {:greater_than_or_equal_to => 0}

  validate :check_days
  validate :check_startdate, on: :create
  validate :order_count_check_for_individual
  validate :check_schedule_budget_per_meal, unless: lambda{|r| (r.will_save_change_to_parent_status? && r.will_save_change_to_status?) || r.buffet?}
  validate :ban_restaurant_address
  validate :restaurants_with_menu_type,if: lambda{|r| r.buffet?}
  validate :check_cuisines_presence, on: :create

  after_update :destroy_schedular_fields, if: lambda{|r| r.saved_change_to_company_id?}
  after_create :schedulers_script

  def add_company
    self.company_id = self.address.addressable.id
  end

  def check_copay
    unless self.per_user_copay?
      self.per_user_copay_amount = 0
    end
  end

  def order_count_check_for_individual
    if self.orders_count.to_i < 1
      errors.add(:orders_count, "can't be less than 1")
    end
  end

  def check_schedule_budget_per_meal
    if self.address.present?
      company = Company.find(self.address.addressable.id)
      if self.per_meal_budget.to_f < company.user_meal_budget
        errors.add(:per_meal_budget, "can't be less than #{company.user_meal_budget} for per meal budget")
      end
      if self.per_meal_budget.to_f > 50
        errors.add(:per_meal_budget, "can't be greater than 50 for per meal budget")
      end
    end
  end

  def destroy_schedular_fields
    self.runningmenufields.joins(:field).where("fields.company_id = ?", saved_changes[:company_id][0]).destroy_all
  end

  def check_cuisines_change
    @cuisines_changed = cuisines_recurring_menus.select { |cuisine| cuisine.new_record? || cuisine.marked_for_destruction? }.any?
  end

  def ban_restaurant_address
    if self.address.present? && self.address.addressable.ban_addresses.exists?(:address_id=> self.address_ids) && !self.approve_ban_restaurant?
      errors.add(:address_ids, "The selected restaurant is on this company’s banned restaurant list")
    elsif self.address.present? && self.approve_ban_restaurant? && !self.address.addressable.ban_addresses.exists?(:address_id=> self.address_ids)
      self.approve_ban_restaurant = false
    end
  end

  def restaurants_with_menu_type
    if RestaurantAddress.where(id: self.address_ids).joins(:menu_buffet).uniq.count < self.addresses_recurring_schedulers.size
      errors.add(:address_ids, "Can't add addresses other than #{self.menu_type}.")
    end
  end

  def check_cuisines_presence
    errors.add(:cuisine_ids, "Cuisines can't be blank") if self.cuisines.blank?
  end

  def scheduler_budget
    self.per_meal_budget + ((self.company.reduced_markup_check && self.company.reduced_markup > 0 && !self.company.enable_saas) ? self.company.markup * self.company.reduced_markup / 100 : 0)
  end

  def check_days
    if self.monday.blank? && self.tuesday.blank? && self.wednesday.blank? && self.thursday.blank? && self.friday.blank? && self.saturday.blank? && self.sunday.blank?
      errors.add(:startdate, "at least 1 day must be selected above")
    end
  end

  def check_startdate
    num_of = self.individual? ? 1 : 2
    if self.startdate.present? && self.startdate < Time.current+num_of.days
      errors.add(:startdate, "Should be greater than or equals to #{(Time.current+num_of.days).to_date}")
    end
  end

  def startdate_timezone
    self.startdate.in_time_zone(self.company.time_zone)
  end

  def set_startdate_as_utc
    if self.startdate.present? && self.address.present?
      n = self.startdate.in_time_zone(self.address.addressable.time_zone).formatted_offset.to_f
      self.startdate = (self.startdate - n.hours)
    end
  end

  def set_cut_offs(recurring_scheduler, date)
    delivery_at = DateTime.new.in_time_zone(ENV["TIMEZONE"]).change(year: date.year, month: date.month, day: date.day, hour: recurring_scheduler.startdate_timezone.hour, min: recurring_scheduler.startdate_timezone.min, sec: recurring_scheduler.startdate_timezone.sec)
    activation_time = Time.current
    # if delivery_at.to_date.monday?
    #   cutoff_at = delivery_at.midnight - 3.days + 14.hours
    #   admin_cutoff_at = delivery_at.midnight - 3.days + 14.hours
    # elsif recurring_scheduler.buffet? || delivery_at.to_date.sunday?
    #   cutoff_at = delivery_at.midnight - 2.days + 14.hours
    #   admin_cutoff_at = delivery_at.midnight - 2.days + 14.hours
    # else
    #   cutoff_at = delivery_at.midnight - 1.days + 14.hours
    #   admin_cutoff_at = delivery_at.midnight - 1.days + 14.hours
    # end
    if recurring_scheduler.first_restaurant.present?
      restaurant_address = RestaurantAddress.find recurring_scheduler.first_restaurant
      # cutoff_at = delivery_at - (recurring_scheduler.individual? ? restaurant_address.individual_meals_cutoff : restaurant_address.buffet_cutoff).hour
      # admin_cutoff_at = delivery_at - (recurring_scheduler.individual? ? restaurant_address.individual_meals_cutoff : restaurant_address.buffet_cutoff).hour
    else
      # n = recurring_scheduler.individual? ? 22 : 48
      # cutoff_at = delivery_at - (n).hour
      # admin_cutoff_at = delivery_at - (n).hour
    end
    cutoff_at = delivery_at - recurring_scheduler.cutoff_hours.hours - recurring_scheduler.cutoff_minutes.minutes
    admin_cutoff_at = delivery_at - recurring_scheduler.admin_cutoff_hours.hours - recurring_scheduler.admin_cutoff_minutes.minutes
    pickup_at = delivery_at - recurring_scheduler.pickup_hours.hours - recurring_scheduler.pickup_minutes.minutes
    [delivery_at, activation_time, cutoff_at, admin_cutoff_at, pickup_at]
  end

  def generate_scheduler_call(date, recurring_scheduler)
    error = nil
    err_date = date.strftime("%a, %d %B %Y") + " : "
    cutoffs = set_cut_offs(recurring_scheduler, date)
    delivery_at = cutoffs[0]
    activation_time = cutoffs[1]
    cut_off = cutoffs[2]
    admin_cut_off = cutoffs[3]
    pickup_at = cutoffs[4]
    runningmenu_id = nil

    if recurring_scheduler.address.active? && recurring_scheduler.user.active? && !recurring_scheduler.addresses.pluck(:status).include?("deleted")
      if recurring_scheduler.driver.nil? || (recurring_scheduler.driver.present? && recurring_scheduler.driver.active?)
        runningmenu = Runningmenu.new(runningmenu_type: recurring_scheduler.runningmenu_type,
          runningmenu_name: recurring_scheduler.runningmenu_name,
          menu_type: recurring_scheduler.menu_type,
          address_id: recurring_scheduler.address_id,
          user_id: recurring_scheduler.user_id,
          orders_count: recurring_scheduler.orders_count,
          per_meal_budget: recurring_scheduler.per_meal_budget,
          per_user_copay: recurring_scheduler.per_user_copay,
          per_user_copay_amount: recurring_scheduler.per_user_copay_amount,
          special_request: recurring_scheduler.special_request,
          delivery_at: delivery_at,
          activation_at: activation_time,
          cutoff_at: cut_off,
          admin_cutoff_at: admin_cut_off,
          pickup_at: pickup_at,
          driver_id: recurring_scheduler.driver_id,
          tag_list: recurring_scheduler.tag_list,
          hide_meeting: recurring_scheduler.hide_meeting,
          cuisine_ids: recurring_scheduler.cuisine_ids,
          bev_rest_deleted: recurring_scheduler.bev_rest_deleted,
          delivery_instructions: recurring_scheduler.delivery_instructions,
          submitted_from_backend: true,
          recurring_submission: true)
        if runningmenu.save
          # runningmenu.address_ids = (runningmenu.address_ids + recurring_scheduler.address_ids).uniq unless recurring_scheduler.address_ids.blank?
          addr_ids = recurring_scheduler.addresses.where(addresses_recurring_schedulers: { recurring_dynamic_section_id: nil }).pluck(:id)
          runningmenu.address_ids = (runningmenu.address_ids + addr_ids).uniq unless addr_ids.blank?
          recurring_scheduler.runningmenufields.each do |field|
            runningmenu.runningmenufields.create!(runningmenu_id: runningmenu.id,
              field_id: field.field_id,
              fieldoption_id: field.fieldoption_id,
              field_type: field.field_type,
              value: field.value)
          end
          recurring_scheduler.recurring_dynamic_sections.each do |dynamic_section|
            runningmenu.dynamic_sections.create!(
              name: dynamic_section.name,
              icon: dynamic_section.icon,
              tag_list: dynamic_section.tag_list)
          end
          runningmenu_id = runningmenu.id
        else
          error = runningmenu.errors.full_messages[0]
        end
      else
        error = "Driver is not active"
      end
    else
      error = "Selected company admin, company location or restaurant location is not active"
    end
    error = error.nil? ? error : ( err_date + error + " <br>" )
    [error, runningmenu_id]
  end

  def schedulers_script
    errors = []
    recurring_scheduler = self
    date = Time.current+recurring_scheduler.recurrence_days.days
    num_of = recurring_scheduler.individual? ? 1 : 2
    if (recurring_scheduler.startdate > Time.current+num_of.days && recurring_scheduler.startdate < date)
      (recurring_scheduler.startdate_timezone.to_date...date.in_time_zone(self.address.addressable.time_zone)).each do |dat|
        if recurring_scheduler[dat.strftime("%A").downcase.to_sym]
          arr = recurring_scheduler.generate_scheduler_call(dat, recurring_scheduler)
          errors << arr[0]
        end
      end
    end
    self.script_errors = errors.compact.join(", ") unless errors.compact.blank?
  end

  def generate_scheduler(date, recurring_scheduler)
    cutoffs = set_cut_offs(recurring_scheduler, date)
    delivery_at = cutoffs[0]
    activation_time = cutoffs[1]
    cut_off = cutoffs[2]
    admin_cut_off = cutoffs[3]
    pickup_at = cutoffs[4]

    if recurring_scheduler.address.active? && recurring_scheduler.user.active? && !recurring_scheduler.addresses.pluck(:status).include?("deleted")
      if recurring_scheduler.driver.nil? || (recurring_scheduler.driver.present? && recurring_scheduler.driver.active?)
        runningmenu = Runningmenu.new(runningmenu_type: recurring_scheduler.runningmenu_type,
          runningmenu_name: recurring_scheduler.runningmenu_name,
          menu_type: recurring_scheduler.menu_type,
          address_id: recurring_scheduler.address_id,
          user_id: recurring_scheduler.user_id,
          orders_count: recurring_scheduler.orders_count,
          per_meal_budget: recurring_scheduler.per_meal_budget,
          per_user_copay: recurring_scheduler.per_user_copay,
          per_user_copay_amount: recurring_scheduler.per_user_copay_amount,
          special_request: recurring_scheduler.special_request,
          delivery_at: delivery_at,
          activation_at: activation_time,
          cutoff_at: cut_off,
          admin_cutoff_at: admin_cut_off,
          pickup_at: pickup_at,
          driver_id: recurring_scheduler.driver_id,
          tag_list: recurring_scheduler.tag_list,
          hide_meeting: recurring_scheduler.hide_meeting,
          cuisine_ids: recurring_scheduler.cuisine_ids,
          bev_rest_deleted: recurring_scheduler.bev_rest_deleted,
          delivery_instructions: recurring_scheduler.delivery_instructions,
          submitted_from_backend: true,
          recurring_submission: true)
        if runningmenu.save
          # runningmenu.address_ids = (runningmenu.address_ids + recurring_scheduler.address_ids).uniq unless recurring_scheduler.address_ids.blank?
          addr_ids = recurring_scheduler.addresses.where(addresses_recurring_schedulers: { recurring_dynamic_section_id: nil }).pluck(:id)
          runningmenu.address_ids = (runningmenu.address_ids + addr_ids).uniq unless addr_ids.blank?
          recurring_scheduler.runningmenufields.each do |field|
            runningmenu.runningmenufields.create!(runningmenu_id: runningmenu.id,
              field_id: field.field_id,
              fieldoption_id: field.fieldoption_id,
              field_type: field.field_type,
              value: field.value)
          end
          recurring_scheduler.recurring_dynamic_sections.each do |dynamic_section|
            runningmenu.dynamic_sections.create!(
              name: dynamic_section.name,
              icon: dynamic_section.icon,
              tag_list: dynamic_section.tag_list)
          end
        else
          email = ScheduleMailer.recurring_failure(recurring_scheduler, runningmenu.errors.full_messages)
          EmailLog.create(sender: ENV['ORDERS_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        end
      else
        email = ScheduleMailer.recurring_failure(recurring_scheduler, nil)
        EmailLog.create(sender: ENV['ORDERS_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      end
    else
      email = ScheduleMailer.recurring_failure(recurring_scheduler, nil)
      EmailLog.create(sender: ENV['ORDERS_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
    end
  end

  def self.generate_schedulers
    RecurringScheduler.joins(:company).where("TO_CHAR(now() AT TIME ZONE companies.time_zone, 'HHam') = ?", '02am').where('recurring_schedulers.parent_status = ?', 0).each do |recurring_scheduler|
      date_zone = (Time.current+recurring_scheduler.recurrence_days.days).in_time_zone(recurring_scheduler.address.addressable.time_zone)
      if recurring_scheduler.startdate_timezone < date_zone && recurring_scheduler[date_zone.strftime("%A").downcase.to_sym]
        recurring_scheduler.generate_scheduler(date_zone, recurring_scheduler)
      end
    end
  end

end