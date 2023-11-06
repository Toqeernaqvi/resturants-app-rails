class Runningmenu < ApplicationRecord
  extend FriendlyId
  #acts_as_paranoid
  acts_as_ordered_taggable
  acts_as_taggable_tenant :company_id

  friendly_id :address_line, use: :sequentially_slugged
  delegate :address_line, to: :address, :allow_nil => true
  delegate :formatted_delivery_address, to: :address, :allow_nil => true
  has_paper_trail versions: { scope: -> { order("id desc") } }, if: lambda {|r| r.saved_change_to_delivery_at? || r.saved_change_to_cutoff_at? || r.saved_change_to_admin_cutoff_at? || r.saved_change_to_address_id? || r.saved_change_to_runningmenu_type? || r.saved_change_to_menu_type? || r.saved_change_to_status? || r.saved_change_to_parent_status? || r.saved_change_to_per_user_copay? || r.saved_change_to_per_user_copay_amount? || r.saved_change_to_delivery_type? || r.saved_change_to_job_id? || r.saved_change_to_notify_restaurant_job_status? || r.saved_change_to_notify_restaurant_job_error? || r.saved_change_to_cutoff_reached_job_id? || r.saved_change_to_cutoff_reached_job_status? || r.saved_change_to_cutoff_reached_job_error? || r.saved_change_to_admin_cutoff_reached_job_id? || r.saved_change_to_admin_cutoff_reached_job_status? || r.saved_change_to_admin_cutoff_reached_job_error? || r.saved_change_to_buffet_delivery_reminder_job_id? || r.saved_change_to_buffet_delivery_reminder_job_status? || r.saved_change_to_buffet_delivery_reminder_job_error? || r.saved_change_to_cutoff_day_before_job_id? || r.saved_change_to_cutoff_day_before_job_status? || r.saved_change_to_cutoff_day_before_job_error? || r.saved_change_to_cutoff_hour_before_job_id? || r.saved_change_to_cutoff_hour_before_job_status? || r.saved_change_to_cutoff_hour_before_job_error? || r.saved_change_to_restaurant_billing_job_id? || r.saved_change_to_restaurant_billing_job_status? || r.saved_change_to_restaurant_billing_job_error? || r.saved_change_to_survey_job_id? || r.saved_change_to_survey_job_status? || r.saved_change_to_survey_job_error? || r.saved_change_to_fleet_create_task_job_id? || r.saved_change_to_fleet_create_task_job_status? || r.saved_change_to_fleet_create_task_job_error? || r.saved_change_to_fleet_update_task_job_id? || r.saved_change_to_fleet_update_task_job_status? || r.saved_change_to_fleet_update_task_job_error? }
  belongs_to :address
  belongs_to :user
  belongs_to :company, optional: true
  belongs_to :latest_version, optional: true, foreign_key: :latest_version_id, class_name: 'PaperTrail::Version'
  has_many :addresses_runningmenus
  has_many :addresses, through: :addresses_runningmenus, dependent: :destroy
  has_many :addressables, through: :addresses
  has_many :orders, dependent: :destroy
  has_many :share_meetings, dependent: :destroy
  # belongs_to :runningmenu_request, optional: true
  has_many :cuisines_menus, dependent: :destroy
  has_many :cuisines, through: :cuisines_menus
  has_many :ratings, as: :ratingable
  has_many :runningmenufields
  belongs_to :cancelled_by, class_name: "User", optional: true
  belongs_to :driver, optional: true
  has_many :dynamic_sections
  accepts_nested_attributes_for :runningmenufields, allow_destroy: true
  accepts_nested_attributes_for :cuisines_menus, allow_destroy: true
  accepts_nested_attributes_for :dynamic_sections, allow_destroy: true

  enum runningmenu_type: [:dont_care, :lunch, :dinner, :breakfast]
  enum status: [:approved, :pending, :cancelled]
  enum menu_type: [:individual, :buffet]
  enum parent_status: [:active, :deleted], _prefix: :parent_status
  enum task_status: [:not_created, :created, :started, :arrived, :completed], _prefix: 'task_status'
  enum pickup_task_status: [:not_created, :created, :started, :arrived, :completed], _prefix: 'pickup_task'
  enum delivery_type: [:pickup, :delivery]
  enum notify_restaurant_job_status: [:pending, :processed, :not_processed], _prefix: 'notify_restaurant_job'
  enum cutoff_reached_job_status: [:pending, :processed, :not_processed], _prefix: 'cutoff_reached_job'
  enum admin_cutoff_reached_job_status: [:pending, :processed, :not_processed], _prefix: 'admin_cutoff_reached_job'
  enum buffet_delivery_reminder_job_status: [:pending, :processed, :not_processed], _prefix: 'buffet_delivery_reminder_job'
  enum cutoff_day_before_job_status: [:pending, :processed, :not_processed], _prefix: 'cutoff_day_before_job'
  enum admin_cutoff_day_before_job_status: [:pending, :processed, :not_processed], _prefix: 'admin_cutoff_day_before_job'
  enum cutoff_hour_before_job_status: [:pending, :processed, :not_processed], _prefix: 'cutoff_hour_before_job'
  enum admin_cutoff_hour_before_job_status: [:pending, :processed, :not_processed], _prefix: 'admin_cutoff_hour_before_job'
  enum restaurant_billing_job_status: [:pending, :processed, :not_processed], _prefix: 'restaurant_billing_job'
  enum survey_job_status: [:pending, :processed, :not_processed], _prefix: 'survey_job'
  enum fleet_create_task_job_status: [:pending, :processed, :not_processed], _prefix: 'fleet_create_task_job'
  enum fleet_update_task_job_status: [:pending, :processed, :not_processed], _prefix: 'fleet_update_task_job'

  attr_accessor :dynamic_sections_address_ids, :updated_from_frontend, :created_from_frontend, :skip_set_dates, :submitted_from_backend, :submitted_from_bulk_upload, :submitted_from_bulk_upload_new, :bev_rest_deleted, :user_at_update, :skip_cuttoff_check, :selected_driver_id, :restaurant_deleted, :deleted_restaurant_name, :recurring_submission, :stop_timezone_callback, :multiple_del_rests, :skip_set_jobs
  
  before_validation :check_addresses_count, if: lambda { |r| r.delivery? && r.multiple_del_rests == true }
  before_validation :set_dates_as_utc, if: lambda { |r| r.created_from_frontend.blank? && r.updated_from_frontend.blank? && r.skip_set_dates.blank?}
  before_validation :set_runnningmenu_time, if: lambda{|r| r.end_time.present? && r.end_time_changed? && submitted_from_bulk_upload.blank?}
  before_validation :calculate_time, if: lambda{|r| ((r.end_time.present? && r.end_time_was&.strftime("%H:%M") != r.end_time.strftime("%H:%M")) || (r.end_time.present? && r.delivery_at.present? && r.will_save_change_to_delivery_at?)) && (r.new_record? || r.updated_from_frontend) && r.recurring_submission.blank? && submitted_from_bulk_upload.blank? }
  before_validation :delivery_type_change_privilege, if: lambda {|r| r.will_save_change_to_delivery_type?}
  before_validation :check_cuisines_change
  before_validation :detach_old_restaurants, if: lambda { |r| r.pending? && r.will_save_change_to_menu_type? && r.addresses.active.count > 0 }

  validates :runningmenu_type, :delivery_at, :activation_at, :cutoff_at, :admin_cutoff_at, :pickup_at, :runningmenu_name, :user_id, presence: true
  validates :runningmenu_type, inclusion: { in: %w(lunch dinner breakfast), message: "Please select Lunch, Dinner or Breakfast of schedules." }
  validates :per_meal_budget, :orders_count, :per_user_copay_amount,  numericality: {:greater_than_or_equal_to => 0}
  validate :schdelue_not_on_current_date, if: lambda{|r| r.new_record? && r.user.present? && !r.user.admin? && !r.address.addressable.enable_saas && r.pickup? }
  validate :delivary_date_cannot_be_in_the_past, unless: lambda{|r| r.cancelled? }
  validate :cutoff_date_cannot_be_in_the_past, unless: lambda{|r| (r.end_time.present? && r.end_time_changed?) || r.skip_cuttoff_check || r.cancelled? || (r.driver_id_changed? && (r.delivery_at - 70.minutes) > Time.current) || r.admin_cutoff_at_changed? || (r.user_at_update.present? && r.user_at_update.company_admin? && r.admin_cutoff_at > Time.current)}
  validate :admin_cutoff_date_cannot_be_in_the_past, unless: lambda{|r| (r.end_time.present? && r.end_time_changed?) || r.skip_cuttoff_check || r.cancelled? || (r.driver_id_changed? && (r.delivery_at - 70.minutes) > Time.current)}
  validate :order_count_check_for_individual, unless: lambda{|r| r.marketplace }
  validate :check_schedule_budget_per_meal, unless: lambda{|r| (r.will_save_change_to_parent_status? && r.will_save_change_to_status?) || r.buffet?}  
  validate :runningmenu_validate_cutoffs, unless: lambda{|r| r.cancelled? || r.skip_cuttoff_check}
  validates_length_of :orders_count, in: 1..5, unless: lambda{|r| r.marketplace }  
  validate :runningmenu_delivery_at, if: lambda{|r| r.will_save_change_to_delivery_at? && !r.new_record?}
  validate :ban_restaurant_address
  validate :menu_type_not_change_after_approved, if: lambda{|r| r.approved? && !r.new_record? && r.menu_type_changed?}
  validate :restaurants_with_menu_type,if: lambda{|r| r.buffet?}
  validate :check_cuisines_presence, on: :create, if: lambda{|r| r.submitted_from_backend.present?}
  validate :check_pickup_at, if: lambda { |r| r.pickup_at_changed? }

  before_create :set_delivery_type, if: lambda{|r| r.created_from_frontend && r.company.enable_marketplace && r.addresses.present? }
  # before_save :add_company
  #after_save :set_pending_status, if: lambda{|r| (r.addresses.active - Restaurant.find_by_name(ENV['BEV_AND_MORE']).addresses.active).count > 0 && r.pending? && !r.updated_from_frontend && !r.restaurant_deleted}
  #after_save :set_status, if: lambda{|r| !r.addresses.present? && r.approved? && !r.restaurant_deleted}
  # before_save :set_end_time, if: lambda{|r| r.delivery_at_changed?}
  #after_save :set_driver_at_onfleet, if: lambda{|r| r.driver_id_changed?}
  #after_save :send_cancellation_email, if: lambda{|r| r.parent_status_deleted? && r.cancel_reason.present?}
  # after_update :destroy_schedular_fields, if: lambda{|r| r.saved_change_to_company_id?}
  # after_update :set_data_for_update_email, if: lambda { |r| !r.updated_from_frontend.blank? }

  #after_save :auto_schedule_restaurants, if: lambda { |r| ( r.saved_change_to_address_id? || r.saved_change_to_delivery_at? || (r.addresses.active - Restaurant.find_by_name(ENV['BEV_AND_MORE']).addresses.active).count < 1 ) && r.pending? && r.pickup? && (r.orders.count==0) && ((r.individual? && !r.address.send("#{r.runningmenu_type}_sequence").blank?) || (r.buffet? && !r.address.buffet_sequence.blank?) ) }
  #after_save :send_schedule_placed_email, if: lambda { |r| (r.pending? || r.company.enable_marketplace) && r.saved_change_to_id? }
  #after_save :send_email_for_cancel_schedule, if: lambda{|r| r.cancelled?}
  # before_save :check_copay, if: lambda {|r| r.will_save_change_to_per_user_copay?}
  #after_save :set_beverages_restaurant_for_buffet, if: lambda{|r| r.submitted_from_backend.blank? && r.created_from_frontend }
  #after_save :set_delivery_instructions, if: lambda { |r| r.saved_change_to_address_id? && r.company.enable_marketplace && (r.created_from_frontend || r.updated_from_frontend) }
  before_save :before_save_meeting
  after_update :after_update_meeting
  after_save :after_save_meeting
  after_commit :after_commit_meeting, on: [:create, :update], if: lambda { |r| r.skip_set_jobs.nil? }

  def delivery_at_timezone
    self.delivery_at.in_time_zone(self.company.time_zone)
  end
  def activation_at_timezone
    self.activation_at.in_time_zone(self.company.time_zone)
  end
  def cutoff_at_timezone
    self.cutoff_at.in_time_zone(self.company.time_zone)
  end
  def admin_cutoff_at_timezone
    self.admin_cutoff_at.in_time_zone(self.company.time_zone)
  end
  def pickup_at_timezone
    self.pickup_at.in_time_zone(self.company.time_zone)
  end

  def set_dates_as_utc
    if self.address.present? && self.delivery_at.present? && self.activation_at.present? && self.cutoff_at.present? && self.admin_cutoff_at.present? && self.pickup_at.present?
      if @stop_timezone_callback != true && stop_timezone_callback != true
        delivery_n = self.delivery_at.in_time_zone(self.address.addressable.time_zone).formatted_offset.to_f
        cutoff_n = self.cutoff_at.in_time_zone(self.address.addressable.time_zone).formatted_offset.to_f
        admin_cutoff_n = self.admin_cutoff_at.in_time_zone(self.address.addressable.time_zone).formatted_offset.to_f
        pickup_n = self.pickup_at.in_time_zone(self.address.addressable.time_zone).formatted_offset.to_f
        self.delivery_at = (self.delivery_at - delivery_n.hours)
        self.activation_at = (self.activation_at - delivery_n.hours)
        self.cutoff_at = (self.cutoff_at - cutoff_n.hours)
        self.admin_cutoff_at = (self.admin_cutoff_at - admin_cutoff_n.hours)
        self.pickup_at = (self.pickup_at - pickup_n.hours)
      end
    end
  end

  def generate_invoice_job
    if self.orders.active.count
      InvoiceWorker.perform_at(self.delivery_at.utc, self.id)
      self.update_column(:enqueued_for_invoice, true)
    end
  end

  def detach_old_restaurants
    self.addresses_runningmenus.destroy_all
  end

  def addresses_count_other_than_bev_and_more
    self.addresses.active.joins("INNER JOIN restaurants ON restaurants.id = addresses.addressable_id AND addresses.addressable_type = 'Restaurant' AND restaurants.name <> '#{ENV["BEV_AND_MORE"]}'").count
  end

  def before_save_meeting
    set_company
    set_end_time if self.delivery_at_changed?
    check_copay if self.will_save_change_to_per_user_copay?
  end

  def after_update_meeting
    destroy_schedular_fields if self.saved_change_to_company_id?
    set_data_for_update_email if !self.updated_from_frontend.blank?
  end

  def after_save_meeting
    set_pending_status if self.addresses_count_other_than_bev_and_more > 0 && self.pending? && !self.updated_from_frontend && !self.restaurant_deleted
    set_status if !self.addresses.present? && self.approved? && !self.restaurant_deleted
    set_driver_at_onfleet if self.driver_id_changed?
    send_cancellation_email if self.parent_status_deleted? && self.cancel_reason.present?
    auto_schedule_restaurants if ( self.saved_change_to_address_id? || self.saved_change_to_delivery_at? || self.addresses_count_other_than_bev_and_more < 1 ) && self.pending? && self.pickup? && (self.orders.count==0) && ((self.individual? && !self.address.send("#{self.runningmenu_type}_sequence").blank?) || (self.buffet? && !self.address.buffet_sequence.blank?) )
    send_schedule_placed_email if (self.pending? || self.company.enable_marketplace) && self.saved_change_to_id?
    send_email_for_cancel_schedule if self.cancelled?
    set_beverages_restaurant_for_buffet if self.submitted_from_backend.blank? && self.created_from_frontend
    set_delivery_instructions if self.saved_change_to_address_id? && self.company.enable_marketplace && (self.created_from_frontend || self.updated_from_frontend)
  end

  def after_commit_meeting
    set_cutoff_day_before_job if self.approved? && self.individual? && !self.hide_meeting && self.cutoff_at > Time.current && (self.cutoff_day_before_job_id.blank? || (self.saved_change_to_menu_type? || self.saved_change_to_hide_meeting? || self.saved_change_to_cutoff_at?))
    # Commented out to further investigate
    # set_admin_cutoff_day_before_job if self.approved? && self.individual? && !self.hide_meeting && self.admin_cutoff_at > Time.current && (self.admin_cutoff_day_before_job_id.blank? || (self.saved_change_to_menu_type? || self.saved_change_to_hide_meeting? || self.saved_change_to_admin_cutoff_at?))
    set_cutoff_hour_before_job if self.approved? && self.individual? && !self.hide_meeting && self.cutoff_at > Time.current && (self.cutoff_hour_before_job_id.blank? || (self.saved_change_to_menu_type? || self.saved_change_to_hide_meeting? || self.saved_change_to_cutoff_at?))
    # Commented out to further investigate
    # set_admin_cutoff_hour_before_job if self.approved? && self.individual? && !self.hide_meeting && self.admin_cutoff_at > Time.current && (self.admin_cutoff_hour_before_job_id.blank? || (self.saved_change_to_menu_type? || self.saved_change_to_hide_meeting? || self.saved_change_to_admin_cutoff_at?))
    set_cutoff_job if self.approved? && self.cutoff_at > Time.current && (self.cutoff_reached_job_id.blank? || (self.saved_change_to_status? || self.saved_change_to_cutoff_at?))
    set_admin_cutoff_reached_job if self.approved? && self.admin_cutoff_at > Time.current && (self.admin_cutoff_reached_job_id.blank? || self.saved_change_to_admin_cutoff_at?)
    set_buffet_delivery_reminder_job if self.approved? && self.buffet? && (self.delivery_at >= Time.current+1.day) && self.cutoff_at < Time.current-1.day && (self.buffet_delivery_reminder_job_id.blank? || (self.saved_change_to_menu_type? || self.saved_change_to_delivery_at? || self.saved_change_to_cutoff_at?))
    set_restaurant_billing_job if self.approved? && self.pickup? && self.delivery_at > Time.current && (self.restaurant_billing_job_id.blank? || (self.saved_change_to_delivery_type? || self.saved_change_to_delivery_at?))
    set_survey_job if self.approved? && self.individual? && !self.hide_meeting && self.delivery_at > Time.current && (self.survey_job_id.blank? || (self.saved_change_to_menu_type? || self.saved_change_to_hide_meeting? || self.saved_change_to_delivery_at?))
    set_fleet_create_task_job if self.approved? && self.cutoff_at > Time.current && (self.fleet_create_task_job_id.blank? || self.saved_change_to_cutoff_at?)
    set_fleet_update_task_job if self.approved? && self.admin_cutoff_at > Time.current && (self.fleet_update_task_job_id.blank? || self.saved_change_to_admin_cutoff_at?)
    notify_driver
  end

  def set_user_pending_amount_job
    if self.user_pending_amount_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.user_pending_amount_job_id)
      job.delete unless job.nil?
    end
    time = self.delivery_at_timezone
    time = time+1.day if time.hour >= 14
    job_id = CalculateUserPendingAmountWorker.perform_at(time.change(hour: 14).utc, self.id)
    self.user_pending_amount_job_id.blank? ? self.update_attributes(user_pending_amount_job_id: job_id, skip_set_dates: true) : self.update_columns(user_pending_amount_job_id: job_id)
  end

  def set_fleet_update_task_job
    if self.fleet_update_task_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.fleet_update_task_job_id)
      job.delete unless job.nil?
    end
    job_id = FleetUpdateTaskWorker.perform_at(self.admin_cutoff_at.utc, self.id)
    self.fleet_update_task_job_id.blank? ? self.update_attributes(fleet_update_task_job_id: job_id, skip_set_dates: true) : self.update_columns(fleet_update_task_job_id: job_id)
  end

  def set_fleet_create_task_job
    if self.fleet_create_task_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.fleet_create_task_job_id)
      job.delete unless job.nil?
    end
    job_id = FleetCreateTaskWorker.perform_at(self.cutoff_at.utc, self.id)
    self.fleet_create_task_job_id.blank? ? self.update_attributes(fleet_create_task_job_id: job_id, skip_set_dates: true) : self.update_columns(fleet_create_task_job_id: job_id)
  end

  def set_survey_job
    if self.survey_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.survey_job_id)
      job.delete unless job.nil?
    end
    job_id = OrderSurveyWorker.perform_at((self.delivery_at+1.hour).utc, self.id)
    self.survey_job_id.blank? ? self.update_attributes(survey_job_id: job_id, skip_set_dates: true) : self.update_columns(survey_job_id: job_id)
  end

  def set_restaurant_billing_job
    if self.restaurant_billing_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.restaurant_billing_job_id)
      job.delete unless job.nil?
    end
    job_id = RestaurantBillingWorker.perform_at(Runningmenu.restaurant_billing_schedule_at(self.id, self.delivery_at.utc), self.id)
    self.restaurant_billing_job_id.blank? ? self.update_attributes(restaurant_billing_job_id: job_id, skip_set_dates: true) : self.update_columns(restaurant_billing_job_id: job_id)
  end

  def self.restaurant_billing_schedule_at(meeting_id, delivery_at)
    if Runningmenu.approved.pickup.where("id != ?", meeting_id).where(delivery_at: delivery_at).exists?
      delivery_at = delivery_at + (Runningmenu.approved.pickup.where("id != ?", meeting_id).where(delivery_at: delivery_at).count+1).minutes
      Runningmenu.restaurant_billing_schedule_at(meeting_id, delivery_at)
    end
    delivery_at
  end

  def set_cutoff_day_before_job
    if self.cutoff_day_before_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.cutoff_day_before_job_id)
      job.delete unless job.nil?
    end
    job_id = CutoffDayBeforeWorker.perform_at((self.cutoff_at-24.hours).utc, self.id)
    self.cutoff_day_before_job_id.blank? ? self.update_attributes(cutoff_day_before_job_id: job_id, skip_set_dates: true) : self.update_columns(cutoff_day_before_job_id: job_id)
  end

  def set_admin_cutoff_day_before_job
    if self.admin_cutoff_day_before_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.admin_cutoff_day_before_job_id)
      job.delete unless job.nil?
    end
    job_id = AdminCutoffDayBeforeWorker.perform_at((self.admin_cutoff_at-24.hours).utc, self.id)
    self.admin_cutoff_day_before_job_id.blank? ? self.update_attributes(admin_cutoff_day_before_job_id: job_id, skip_set_dates: true) : self.update_columns(admin_cutoff_day_before_job_id: job_id)
  end

  def set_cutoff_hour_before_job
    if self.cutoff_hour_before_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.cutoff_hour_before_job_id)
      job.delete unless job.nil?
    end
    job_id = CutoffHourBeforeWorker.perform_at((self.cutoff_at-1.hour).utc, self.id)
    self.cutoff_hour_before_job_id.blank? ? self.update_attributes(cutoff_hour_before_job_id: job_id, skip_set_dates: true) : self.update_columns(cutoff_hour_before_job_id: job_id)
  end

  def set_admin_cutoff_hour_before_job
    if self.admin_cutoff_hour_before_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.admin_cutoff_hour_before_job_id)
      job.delete unless job.nil?
    end
    job_id = AdminCutoffHourBeforeWorker.perform_at((self.admin_cutoff_at-1.hour).utc, self.id)
    self.admin_cutoff_hour_before_job_id.blank? ? self.update_attributes(admin_cutoff_hour_before_job_id: job_id, skip_set_dates: true) : self.update_columns(admin_cutoff_hour_before_job_id: job_id)
  end

  def set_before_pickup_job
    self.addresses_runningmenus.each do |addr_runningmenu|
      addr_runningmenu.set_before_pickup_job unless addr_runningmenu.address.contact_numbers.blank?
    end
  end

  def set_cutoff_job
    if self.cutoff_reached_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.cutoff_reached_job_id)
      job.delete unless job.nil?
    end
    job_id = CutoffReachedWorker.perform_at((self.cutoff_at).utc, self.id)
    self.cutoff_reached_job_id.blank? ? self.update_attributes(cutoff_reached_job_id: job_id, skip_set_dates: true) : self.update_columns(cutoff_reached_job_id: job_id)
  end

  def set_admin_cutoff_reached_job
    if self.admin_cutoff_reached_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.admin_cutoff_reached_job_id)
      job.delete unless job.nil?
    end
    job_id = AdminCutoffReachedWorker.perform_at((self.admin_cutoff_at).utc, self.id)
    self.admin_cutoff_reached_job_id.blank? ? self.update_attributes(admin_cutoff_reached_job_id: job_id, skip_set_dates: true) : self.update_columns(admin_cutoff_reached_job_id: job_id)
  end

  #Job for Reminder of Day before buffet delivery
  def set_buffet_delivery_reminder_job
    if self.buffet_delivery_reminder_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.buffet_delivery_reminder_job_id)
      job.delete unless job.nil?
    end
    job_id = BuffetDeliveryReminderWorker.perform_at((self.delivery_at.yesterday).utc, self.id)
    self.buffet_delivery_reminder_job_id.blank? ? self.update_attributes(buffet_delivery_reminder_job_id: job_id, skip_set_dates: true) : self.update_columns(buffet_delivery_reminder_job_id: job_id)
  end

  def notify_driver
    driver = Driver.find_by_id(self.driver_id.nil? ? self.driver_id_before_last_save : self.driver_id)
    if self.saved_change_to_driver_id? && !self.driver_id.nil? && !driver.nil?
      driver.scheduled_meeting(self)
    elsif self.saved_change_to_driver_id? && self.driver_id.nil? && !driver.nil?
      driver.cancelled_meeting(self)
    end
  end

  def auto_schedule_restaurants
    if self.individual?
      sequence_type_id = "#{self.runningmenu_type}_sequence_id"
      sequence = self.address.send("#{self.runningmenu_type}_sequence")
    else
      sequence_type_id = "buffet_sequence_id"
      sequence = self.address.buffet_sequence
    end
    bev_rest = Restaurant.active.find_by_name(ENV['BEV_AND_MORE']).addresses.active.last
    company_meeting = Runningmenu.joins(:address).where("runningmenus.status != ? AND runningmenus.address_id != ? AND addresses.status = ? AND runningmenus.company_id = ? AND DATE(runningmenus.delivery_at) = ? AND #{sequence_type_id} = ?", Runningmenu.statuses[:cancelled], self.address_id, Address.statuses[:active], self.company_id, self.delivery_at, sequence.id).last
    if company_meeting.blank?
      sequence.labels_seqs.each do |box|
        # Restaurant1
        address_appended = false
        box_size = box.cuisines_sequences.size
        box.cuisines_sequences.order(position: :asc).each_with_index do |box_item, box_item_index|
          # row contains American
          break if address_appended
          last_scheduled_box_item_to_address = address.companies_schedules.where(labels_seq_id: box.id).last&.cuisines_sequence
          if box_size > 1 && (last_scheduled_box_item_to_address&.id == box_item.id || (!last_scheduled_box_item_to_address.blank? && (box_item.position < last_scheduled_box_item_to_address&.position ? (last_scheduled_box_item_to_address&.id == box.cuisines_sequences.order(position: :asc).last.id ? false : true) : false) ))
            next
          else
            where_str = company.ban_addresses.exists? ? "address_id NOT IN(#{company.ban_addresses.pluck(:address_id).join(',')})" : ""
            box_item_restaurants_size = box_item.cuisineslist.addresses_cuisineslists.where(where_str).count
            box_item_addresses = box_item.cuisineslist.addresses_cuisineslists.where(where_str).order(position: :asc)
            box_item_last_address = box_item_addresses&.last
            last_scheduled_addresses_cuisineslist = address.companies_schedules.where(cuisineslist_id: box_item.cuisineslist_id).last&.addresses_cuisineslist
            box_item_addresses.each do |rest_address|
              # row contains Mcdonald's j3 johar town lahore
              if (rest_address.address.enable_self_service) || ( box_item_restaurants_size > 1 && (  last_scheduled_addresses_cuisineslist&.id == rest_address.id || (!last_scheduled_addresses_cuisineslist.blank? && (rest_address.position < last_scheduled_addresses_cuisineslist.position ? ( last_scheduled_addresses_cuisineslist.id == box_item_last_address&.id ? false : true) : false)) || CompaniesSchedule.exists?(restaurant_address_id: rest_address.address_id, delivery_date: delivery_at.to_date) ) )
                next
              else
                cs = address.companies_schedules.create(labels_seq_id: box.id, cuisines_sequence_id: box_item.id, cuisineslist_id: box_item.cuisineslist_id, addresses_cuisineslist_id: rest_address.id, restaurant_address_id: rest_address.address_id, delivery_date: delivery_at.to_date)
                addresses << rest_address.address
                address_appended = true
                break
              end
            end
          end
        end
      end
    else
      addresses << company_meeting.addresses.active.where("addresses.id != ?", bev_rest.id)
    end
    if self.addresses.exists?(id: bev_rest.id) || self.bev_rest_deleted || self.address.addressable.enable_marketplace || self.address.addressable.enable_saas
      # Beverages & More is already added or its deleted by user
    else
      self.addresses << bev_rest
    end
    # self.update_columns(auto_scheduling: true)
    if self.addresses.blank?
      self.update_columns(auto_scheduling: true)
    else
      restaurant_address = self.addresses.first
      cutoff_at = self.delivery_at - (self.individual? ? restaurant_address.individual_meals_cutoff : restaurant_address.buffet_cutoff).hour
      admin_cutoff_at = self.delivery_at - (self.individual? ? restaurant_address.individual_meals_cutoff : restaurant_address.buffet_cutoff).hour
      self.update_columns(auto_scheduling: true, cutoff_at: cutoff_at, admin_cutoff_at: admin_cutoff_at)
    end
  end

  def onfleet_create_task
    if self.user.present? && !self.user.admin?
      admin = self.user
    else
      admin = self.company.company_admins.active.where.not('desk_phone = ?', "").first
    end

    if admin.present?
      ph_no = (admin.sms_notification? && admin.phone_number.present?) ? admin.phone_number : admin.desk_phone
      skip_notification = !admin.sms_notification
    end

    appartment_no = self.address.suite_no.present? ? (self.address.suite_no + " ") : ""
    pickup_task, pickup_task_per_restaurant, dropoff_task = nil, nil, nil
    beverages_orders = self.orders.joins(:fooditem).active.where(restaurant_address_id: Restaurant.find_by_name(ENV['BEV_AND_MORE']).addresses.pluck(:id)).select('fooditems.name AS fooditem_name, SUM(orders.quantity) AS quantity').group('fooditems.name')
    b_orders = ""
    beverages_orders.each do |bo|
      b_orders += "\n#{bo.quantity} #{bo.fooditem_name}"
    end
    pickup_note = "pickup labels and utensils at chowmill.#{b_orders}"
    driver = (self.driver.present? && self.driver.worker_id.present?) ? self.driver : ""
    addresses_collec = Address.where(latitude: '37.4035753199216', longitude: '-121.904924149765').pluck(:id)
    # Onfleet pickup task for chowmill bev and more restaurant start
    if beverages_orders.present?
      begin
        pickup_task = Onfleet::Task.create(
          destination: {
            address: {
              unparsed: '2345 Harris Way, San Jose, CA 95133' #address.formatted
            },
          },
          recipients: [],
          pickup_task: true,
          # complete_before: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : ((self.delivery_at_timezone - 60.minutes).to_f * 1000).to_i,
          # complete_after: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : ((self.delivery_at_timezone - 70.minutes).to_f * 1000).to_i,
          complete_before: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : (self.pickup_at_timezone.to_f * 1000).to_i,          
          complete_after: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : (self.pickup_at_timezone.to_f * 1000).to_i,
          notes: "Meeting Name: #{self.runningmenu_name}, Order Number: #{self.id}, "+pickup_note,
          quantity: beverages_orders.sum(&:quantity),
          service_time: 10,
        )
        if pickup_task.present?
          if driver.present?
            Onfleet::Task.update(pickup_task.id, {worker: driver.worker_id})
          end
          self.update_column(:pickup_task_id, pickup_task.id)
          puts "OnFleet: B&M Task created for pickup"
        else
          puts "OnFleet: B&M Task failed to for pickup"
        end
      rescue StandardError => e
        subject = "OnFleet: Pickup B&M Task failed for Scheduler #{self.id}"
        email = ScheduleMailer.onfleet_task_failed(self, subject, e.message)
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        puts "OnFleet: B&M #{e.message}"
      end
    end
    # Onfleet pickup task for chowmill bev and more restaurant end

    self.addresses.where.not(addressable_id: Restaurant.active.find_by_name(ENV['BEV_AND_MORE']).id).each do |address|
      if self.orders.active.where(restaurant_address_id: address.id).exists?
        begin
          dependency = []
          if pickup_task.present?
            dependency.push(pickup_task.id)
          end
          unless addresses_collec.include?(address.id)
            pickup_task_per_restaurant = Onfleet::Task.create(
              destination: {
                address: {
                  name: address.name,
                  unparsed: (address.suite_no.present? ? (address.suite_no + " ") : "") + address.address_line
                },
              },
              recipients: [],
              dependencies: dependency,
              pickup_task: true,
              # complete_before: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : ((self.delivery_at_timezone - 45.minutes).to_f * 1000).to_i,
              # complete_before: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : ((self.delivery_at_timezone - 60.minutes).to_f * 1000).to_i,
              # complete_after: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : ((self.delivery_at_timezone - 60.minutes).to_f * 1000).to_i,
              complete_before: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : (self.pickup_at_timezone.to_f * 1000).to_i,
              complete_after: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : (self.pickup_at_timezone.to_f * 1000).to_i,
              notes: ("Meeting Name: #{self.runningmenu_name}, Order Number: #{self.id}, "+"Pickup utensils & do inventory of meals."),
              quantity: self.orders.active.where(restaurant_address_id: address.id).sum(:quantity),
            )
            if pickup_task_per_restaurant.present?
              if driver.present?
                Onfleet::Task.update(pickup_task_per_restaurant.id, {worker: driver.worker_id})
              end
              address_runningmenu = AddressesRunningmenu.find_by(address_id: address.id, runningmenu_id: self.id)
              address_runningmenu.update_columns(restaurant_task_id: pickup_task_per_restaurant.id, task_status: :created)
              puts "OnFleet: Task created for restaurant #{address.name}"
            else
              puts "OnFleet: Task failed to create for restaurant #{address.name}"
            end
          end
        rescue StandardError => e
          subject = "OnFleet: Pickup Task failed for Scheduler #{self.id} and address #{address.name}"
          email = ScheduleMailer.onfleet_task_failed(self, subject, e.message)
          EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
          puts "OnFleet: #{e.message}"
        end
      end
    end

    begin
      dependency = []
      if pickup_task_per_restaurant.present? && pickup_task.present?
        dependency.push(pickup_task_per_restaurant.id, pickup_task.id)
      elsif pickup_task.present?
        dependency.push(pickup_task.id)
      elsif pickup_task_per_restaurant.present?
        dependency.push(pickup_task_per_restaurant.id)
      end
      if admin.present?
        dropoff_task = Onfleet::Task.create(
          destination: {
            address: {
              name: self.address.name,
              unparsed: appartment_no + self.address.address_line
            },
            notes:  "#{self.delivery_instructions.blank? ?  '' : "Delivery Instructions: #{self.delivery_instructions}." }"
          },
          recipients: [{
            name: admin.name,
            phone: ph_no,
          }],
          dependencies: dependency,
          pickup_task: false,
          complete_before: ((self.delivery_at_timezone).to_f * 1000).to_i,
          complete_after: self.delivery? ? ((self.delivery_at_timezone).to_f * 1000).to_i : ((self.delivery_at_timezone - 15.minutes).to_f * 1000).to_i,
          notes:  "Meeting Name: #{self.runningmenu_name}, Order Number: #{self.id}",
          quantity: self.orders.exists? ? self.orders.active.sum(:quantity) : 0,
          requirements: {
            photo: true
          },
        )
      else
        subject = "OnFleet: Dropoff Task failed for Scheduler #{self.id}"
        email = ScheduleMailer.onfleet_task_failed(self, subject, "Can't find any company admin for #{self.company.name} as recipient.")
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      end
      if dropoff_task.present?
        if driver.present?
          Onfleet::Task.update(dropoff_task.id, {worker: driver.worker_id})
        end
        self.update_columns(task_id: dropoff_task.id, task_status: :created)
        HTTParty.put("https://onfleet.com/api/v2/recipients/#{dropoff_task.recipients.first.id}", :body => {:skipSMSNotifications=> skip_notification}.to_json, :basic_auth => {:username=>"#{ENV['ONFLEET_API_KEY']}"})
        puts "OnFleet: Dropoff Task Created"
      else
        puts "OnFleet: Dropoff Task Failed to create"
      end
    rescue StandardError => e
      subject = "OnFleet: Dropoff Task failed for Scheduler #{self.id}"
      email = ScheduleMailer.onfleet_task_failed(self, subject, e.message)
      EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      puts "OnFleet: #{e.message}"
    end

  end

  def onfleet_update_task
    pickup_task = nil
    beverages_orders = self.orders.joins(:fooditem).active.where(restaurant_address_id: Restaurant.find_by_name(ENV['BEV_AND_MORE']).addresses.pluck(:id)).select('fooditems.name AS fooditem_name, SUM(orders.quantity) AS quantity').group('fooditems.name')
    b_orders = ""
    restaurant_task_ids  = self.addresses_runningmenus.where.not(restaurant_task_id: nil).pluck(:restaurant_task_id)
    dependency = []
    if restaurant_task_ids.present? && self.task_id.present?
      dependency.push(restaurant_task_ids, self.task_id)
    elsif restaurant_task_ids.present? && !self.task_id.present?
      dependency.push(restaurant_task_ids)
    elsif self.task_id.present?
      dependency.push(self.task_id)
    end
    beverages_orders.each do |bo|
      b_orders += "\n#{bo.quantity} #{bo.fooditem_name}"
    end
    if self.pickup_task_id.present?
      task = Onfleet::Task.get(self.pickup_task_id)
      quantity = beverages_orders.sum(&:quantity)
      if quantity != task.quantity
        task.quantity = quantity
        task.save
      end
    elsif beverages_orders.present? && !self.pickup_task_id.present?
      begin
        pickup_task = Onfleet::Task.create(
          destination: {
            address: {
              unparsed: '2345 Harris Way, San Jose, CA 95133' #address.formatted
            },
          },
          recipients: [],
          pickup_task: true,
          dependencies: dependency.flatten,
          # complete_before: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : ((self.delivery_at_timezone - 60.minutes).to_f * 1000).to_i,
          # complete_after: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : ((self.delivery_at_timezone - 70.minutes).to_f * 1000).to_i,
          complete_before: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : (self.pickup_at_timezone.to_f * 1000).to_i,
          complete_after: self.delivery? ? (self.delivery_at_timezone.to_f * 1000).to_i : (self.pickup_at_timezone.to_f * 1000).to_i,
          notes: "Pickup new labels for changed orders.#{b_orders}",
          quantity: beverages_orders.sum(&:quantity),
          service_time: 10,
        )
        if pickup_task.present?
          if self.driver.present? && self.driver.worker_id.present?
            Onfleet::Task.update(pickup_task.id, {worker: self.driver.worker_id})
          end
          self.update_column(:pickup_task_id, pickup_task.id)
          puts "OnFleet: Task created for pickup"
        else
          puts "OnFleet: Task failed to for pickup"
        end
      rescue StandardError => e
        subject = "OnFleet: Pickup Task failed for Scheduler #{self.id}"
        email = ScheduleMailer.onfleet_task_failed(self, subject, e.message)
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        puts "OnFleet: #{e.message}"
      end
    end
    if self.task_id.present?
      task = Onfleet::Task.get(self.task_id)
      quantity = self.orders.active.sum(:quantity)
      if quantity != task.quantity
        task.quantity = quantity
        task.save
      end
    end
    self.addresses.active.each do |address|
      address_runningmenu = AddressesRunningmenu.find_by(address_id: address.id, runningmenu_id: self.id)
      if address_runningmenu.restaurant_task_id.present?
        task = Onfleet::Task.get(address_runningmenu.restaurant_task_id)
        quantity = self.orders.active.where(restaurant_address_id: address.id).sum(:quantity)
        if quantity != task.quantity
          task.quantity = quantity
          task.save
        end
      end
    end

  end

  def check_pickup_at
    if created_from_frontend.blank? && updated_from_frontend.blank? && pickup_at > delivery_at
      errors.add(:pickup_at, "Can't greater than delivery_at")
    end
  end

  def delivery_type_change_privilege
    unless self.orders.active.blank?
      errors.add(:delivery_type, "Delivery type can't be change now as it has some orders now")
      self.delivery_type = Runningmenu.delivery_types[self.delivery_type_was]
    end
  end

  def check_addresses_count
    errors.add(:address_ids, "Restaurant locations can't be more than 1 in case of delivery type as delivery")
    self.delivery_type = Runningmenu.delivery_types[self.delivery_type_was] unless self.new_record?
  end

  def check_cuisines_presence
    errors.add(:cuisine_ids, "Cuisines can't be blank") if self.cuisines.blank?
  end

  def set_beverages_restaurant_for_buffet
    if !self.address.addressable.enable_marketplace || !self.address.addressable.enable_saas
      restaurant = Restaurant.active.find_by_name ENV['BEV_AND_MORE']
      bev_address = restaurant.addresses.active.last
      if restaurant.present? && !self.address_ids.include?(bev_address&.id)
        self.addresses << bev_address
      end
    end
  end

  def menu_type_not_change_after_approved
    errors.add(:menu_type, "Can't change menu type after schedular approved")
  end

  def restaurants_with_menu_type
    if RestaurantAddress.where(id: self.address_ids).joins(:menu_buffet).uniq.count < self.addresses_runningmenus.size
      errors.add(:address_ids, "Can't add addresses other than #{self.menu_type}.")
    end
  end

  def check_copay
    unless self.per_user_copay?
      self.per_user_copay_amount = 0
    end
  end

  def ban_restaurant_address
    if self.address.present? && self.address.addressable.ban_addresses.exists?(:address_id=> self.address_ids) && !self.approve_ban_restaurant?
      errors.add(:address_ids, "The selected restaurant is on this company’s banned restaurant list")
    elsif self.address.present? && self.approve_ban_restaurant? && !self.address.addressable.ban_addresses.exists?(:address_id=> self.address_ids)
      self.approve_ban_restaurant = false
    end
  end

  def send_email_for_cancel_schedule
    self.orders.update_all(status: Order.statuses[:cancelled])
    self.addresses.active.joins(:contacts).where("contacts.email_summary_check = ?", true).uniq.each do |address|
      pre_email_sent = AddressesRunningmenu.find_by(runningmenu_id: self.id, address_id: address.id).pre_email_sent?
      if pre_email_sent
        TwilioSmsJob.perform_later(self.id, address.id, 'cancelled') unless address.contact_numbers.blank?
        orders = Order.order_summary(self, true, 0, 0, address.id)
        summary_contacts = address.summary_contacts
        cc_contacts = summary_contacts.drop(1)
        contact = summary_contacts.first
        email = ScheduleMailer.changes_to_restaurant(self, orders, address, contact, cc_contacts, "")
        EmailLog.create(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      end
    end
  end

  def runningmenu_delivery_at
    errors.add(:delivery_at, "Can't be updated, delivery date has been passed.") if self.delivery_at_was < Time.current && !self.pending?
  end

  scope :today_runningmenus, -> (time_zone) {
    where(delivery_at: Time.current.in_time_zone(time_zone).beginning_of_day..Time.current.in_time_zone(time_zone).end_of_day)
  }

  scope :tomorrow_runningmenus, -> (time_zone) {
    where(delivery_at: 1.days.from_now.in_time_zone(time_zone).beginning_of_day..1.days.from_now.in_time_zone(time_zone).end_of_day)
  }

  scope :seven_day_runningmenus, -> (time_zone) {
    where(delivery_at: Time.current.in_time_zone(time_zone).beginning_of_day..7.days.since)
  }

  scope :thirty_day_runningmenus, -> (time_zone) {
    where(delivery_at: Time.current.in_time_zone(time_zone).beginning_of_day..30.days.since)
  }

  ransacker :by_days, formatter: proc {|value|
    time_zone = value.split("--")[1]
    value = value.split("--")[0]
    results = Runningmenu.today_runningmenus(time_zone).map(&:id) if value == "Today"
    results = Runningmenu.tomorrow_runningmenus(time_zone).map(&:id) if value == "Tomorrow"
    results = Runningmenu.seven_day_runningmenus(time_zone).map(&:id) if value ==  "Next 7 Days"
    results = Runningmenu.thirty_day_runningmenus(time_zone).map(&:id) if value == "Next 30 Days"
    results = results.present? ? results : nil
   } do |parent|
    parent.table[:id]
  end

  def meal_type
    hour = self.end_time.hour
    case
    when hour >= 7 && hour <= 10
      "breakfast"
    when hour >= 11 && hour <= 14
      "lunch"
    when hour >= 17 && hour < 20
      "dinner"
    else
      "dont_care"
    end
  end

  # def runningmenus_delivery_time(orders)
  #   orders.present? && orders.sum{|order| order.quantity} > 50 ? (self.delivery_at_timezone - 1.hour - 15.minutes).strftime("%I:%M %p") : (self.delivery_at_timezone - 1.hour).strftime("%I:%M %p")
  # end

  # def pickup_time restaurant_address_id
  #   self.orders.active.where(restaurant_address_id: restaurant_address_id).sum(:quantity) > 50 ? (self.delivery_at_timezone - 1.hour - 15.minutes).strftime("%I:%M %p") : (self.delivery_at_timezone - 1.hour).strftime("%I:%M %p")
  # end

  def check_cuisines_change
    @cuisines_changed = cuisines_menus.select { |cuisine| cuisine.new_record? || cuisine.marked_for_destruction? }.any?
  end

  def average_without_water
    order_count = self.orders.active
    if order_count.blank?
      [0.0,"green"]
    else
      total_orders = self.orders.active.where.not(restaurant_address_id: Restaurant.find_by(name: ENV['BEV_AND_MORE']).addresses.active.first.id)
      total_order_price = total_orders.sum(:total_price)
      total_order_quantity = total_orders.sum(:quantity)
      avg_per_meal = total_order_price / total_order_quantity
      avg_per_meal = avg_per_meal.nan? ? 0.0 : avg_per_meal
      [avg_per_meal.to_f.round(2), avg_per_meal.to_f.round(2) < self.per_meal_budget ? "green" : "red"]
    end
  end

  def destroy_schedular_fields
    self.runningmenufields.joins(:field).where("fields.company_id = ?", saved_changes[:company_id][0]).destroy_all
  end

  def init_notify_restaurant_job
    if self.job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.job_id)
      job.delete unless job.nil?
    end
    job_id = MeetingWorker.perform_at((self.approved_at+ENV["MEETING_EMAILS_INTERVAL"].to_i.minutes).utc, self.id)
    self.job_id.blank? ? self.update_attributes(job_id: job_id, skip_set_dates: true) : self.update_attributes(job_id: job_id)
  end

  def notify_restaurant_contacts
    self.addresses.active.uniq.each do |runningmenu_address|
      self.send_first_email(runningmenu_address)
    end
  end

  def send_first_email(runningmenu_address)
    orders = Order.order_summary(self, true, 0, 0, runningmenu_address.id)
    if orders.present?
      # summary_contacts = runningmenu_address.contacts.where(email_summary_check: true)
      # cc_contacts = summary_contacts.all[1..-1]&.map{|c| c.email}      
      TwilioSmsJob.perform_later(self.id, runningmenu_address.id, 'first') unless runningmenu_address.contact_numbers.blank?
      summary_contacts = runningmenu_address.summary_contacts
      cc_contacts = summary_contacts.drop(1)
      contact = summary_contacts.first
      email = ScheduleMailer.changes_to_restaurant(self, orders, runningmenu_address, contact, cc_contacts, 'New')
      EmailLog.create(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      AddressesRunningmenu.find_by(runningmenu_id: self.id, address_id: runningmenu_address.id)&.pre_email_sent!
    end
  end

  def self.restaurant_alert
    from_ = ENV["MEETING_EMAILS_INTERVAL"].to_i+ENV["CHANGES_EMAIL_BEFORE"].to_i
    from = (Time.current - from_.minutes).beginning_of_minute
    to = (Time.current - ENV["CHANGES_EMAIL_BEFORE"].to_i.minutes).beginning_of_minute
    runningmenus = Runningmenu.approved.joins(:orders).where("admin_cutoff_at >= ? AND approved_at <= ?", Time.current, from).uniq
    runningmenus.each do |runningmenu|
      emails = runningmenu.company.company_admins.active.pluck(:email).uniq
      if runningmenu.orders.joins(:versions).where(versions: { created_at: from..to, whodunnit: emails }).count > 0
        runningmenu.addresses.active.each do |address|
          addr_runningmenu = AddressesRunningmenu.find_by(runningmenu_id: runningmenu.id, address_id: address.id)
          if addr_runningmenu&.pre_email_not_sent?
            runningmenu.send_first_email(address)
          #else
            #orders = Order.order_summary(runningmenu, true, 0, 0, address.id)
            #if orders.present?
              #Runningmenu.send_changes_email(runningmenu, address, orders)
            #end
          end
        end
      end
    end
  end

  def self.send_changes_email(runningmenu, address, orders)
    begin
      summary_contacts = address.summary_contacts
      if summary_contacts.present?
        cc_contacts = summary_contacts.drop(1)
        email = ScheduleMailer.changes_to_restaurant(runningmenu, orders, address, summary_contacts.first, cc_contacts, 'Updated')
        email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        email_log.save
      else
        email = ScheduleMailer.changes_to_restaurant(runningmenu, orders, address, nil, [], 'Updated')
        email_log = EmailLog.new(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        email_log.save
      end

    rescue StandardError => e
      puts "Changes_to_restaurant failed due to: #{e.message} - #{Time.current}"
    end
  end

  def send_cancellation_email
    email = ScheduleMailer.cancel_scheduler(self)
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  end

  def scheduler_budget
    self.per_meal_budget + ((self.company.reduced_markup_check && self.company.reduced_markup > 0 && !self.company.enable_saas) ? self.company.markup * self.company.reduced_markup / 100 : 0)
  end

  def set_data_for_update_email
    arr = []
    self.runningmenufields.each do |runningmenufield|
      if runningmenufield.text? && runningmenufield.saved_changes['value'].present?
        arr.push(runningmenufield.saved_changes['value'])
        arr.last.push(runningmenufield.field.id)
      elsif runningmenufield.dropdown? && runningmenufield.saved_changes['fieldoption_id'].present?
        arr.push(runningmenufield.saved_changes['fieldoption_id'])
        arr.last.push(runningmenufield.field.id)
      end
    end
    email = ScheduleMailer.schedule_updated_from_frontend(self, arr, self.saved_changes, self.user_at_update)
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  end

  def send_schedule_placed_email
    email = ScheduleMailer.schedule_placed(self)
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  end

  def set_end_time
    self.end_time = self.delivery_at.strftime "%H:%M"
  end

  def set_runnningmenu_time
    time = self.end_time.strftime "%H:%M:%S"
    splittedtime = time.split(':')
    if self.delivery_at.present?
      self.delivery_at = self.delivery_at.to_date.at_beginning_of_day.beginning_of_day + splittedtime[0].to_i.hours + splittedtime[1].to_i.minutes + splittedtime[2].to_i.seconds
    else
      self.delivery_at = nil
    end
  end

  def user_remaining_budget(user_id, share_meeting_id, exclude_order_id)
    where = "orders.runningmenu_id = #{self.id} AND orders.status = 0"
    where += " AND orders.share_meeting_id = #{share_meeting_id}" if share_meeting_id.present?
    where += " AND orders.user_id = #{user_id}" if user_id.present?
    where += " AND orders.id != #{exclude_order_id}" if exclude_order_id.present?
    already_used_budget = Order.find_by_sql("SELECT SUM((company_price + CASE user_markup WHEN false THEN site_price ELSE 0 END )) AS total FROM orders WHERE #{where}")
    remaining_budget = self.per_meal_budget - already_used_budget.last.total.to_f
    remaining_budget > 0 ? remaining_budget : 0
  end

  def calculate_time
    self.activation_at =  Time.current if self.new_record?
    if self.delivery_at.present?
      self.pickup_at = self.delivery_at - 1.hour - 15.minutes
      if self.addresses.present?
        restaurant_address = self.addresses.first
        self.cutoff_at = self.delivery_at - (self.individual? ? restaurant_address.individual_meals_cutoff : restaurant_address.buffet_cutoff).hour
        self.admin_cutoff_at = self.delivery_at - (self.individual? ? restaurant_address.individual_meals_cutoff : restaurant_address.buffet_cutoff).hour
      else
        n = self.individual? ? 22 : 48
        self.cutoff_at = self.delivery_at - (n).hour
        self.admin_cutoff_at = self.delivery_at - (n).hour
      end
    end
  end

  def as_json(options = nil)
    super({ only: [:id, :slug, :runningmenu_name, :runningmenu_type, :menu_type, :per_meal_budget, :delivery_at, :address_id, :activation_at, :cutoff_at, :admin_cutoff_at, :status, :delivery_instructions, :special_request, :share_token, :per_user_copay, :per_user_copay_amount], methods: [:remaining_time, :delivery_room_value, :headcount_served, :formated_end_time] }.merge(options || {}))
  end

  def headcount_served
    self.buffet? ? self.orders.active.joins(:dishsize).select('SUM(dishsizes.serve_count * orders.quantity) AS headcount_served').group('orders.id').first&.headcount_served : nil
  end

  def formated_end_time
    self.end_time&.strftime "%H:%M"
  end

  def order_count
    self.orders.active.count
  end

  def total_quantity
    self.orders.active.sum(:quantity).to_i
  end

  def remaining_time
    test = self.cutoff_at - Time.now
    if test/1.minute < 1
      test = 'No remaining time'
    else
      test/1.minute
    end
  end

  def delivery_room_value
    str = ""
    str = [self.address.street_number, self.address.street].compact.join(' ')
    str += ', ' if self.address.street_number.present? || self.address.street.present?
    str += self.address.suite_no.present? ? self.address.suite_no + ", " : ""
    str += "#{self.delivery_instructions}, " if self.delivery_instructions.present?
    str += self.address.city if self.address.city.present?
    str.blank? ? nil : str
  end

  def contact_card
    rest_address = self.addresses.where(enable_self_service: true).last
    chowmill_info = {id: nil, name: 'Chowmill', email: 'support@chowmill.com', phone_number: '1-408-883-9415', logo_url: nil }
    return chowmill_info if rest_address.blank?
    rest_admin = User.active.joins(:addresses_vendor).where(primary_contact: true, addresses_vendors: { address_id: rest_address.id} ).last
    return chowmill_info if rest_admin.blank?
    {id: rest_admin.id, name: rest_admin.name, email: rest_admin.email, phone_number: rest_admin.phone_number, restaurant_name: rest_address.addressable.name, logo_url: rest_address.logo.present? ? rest_address.logo_url(:medium) : RestaurantAddress.find(rest_address.id).fooditems.active.where('image IS NOT NULL').first&.image_url(:medium) }
  end

  def set_delivery_instructions
    self.update_columns(delivery_instructions: self.address.delivery_instructions)
  end

  def grouped_orders
    self.orders.active.select {|o| o.group.present?}
  end

  def ungrouped_orders
    self.orders.active.select {|o| o.group.blank?}
  end

  private
  def set_status
    @stop_timezone_callback = true
    self.pending!
  end

  def set_pending_status
    self.update_columns(status: Runningmenu.statuses[:approved], approved_at: Time.current)
    self.init_notify_restaurant_job
    if self.company.company_admins.active.present? && self.approved? && !self.company.enable_marketplace
      self.company.company_admins.active.each do |admin|
        if (admin.menu_ready_email && !self.csv_imported) || (self.csv_imported && self.notify_admin)
          email = ScheduleMailer.schedule_ready(admin, self)
          EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        end
      end
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

  def schdelue_not_on_current_date
    if self.delivery_at.present? && self.delivery_at.to_date.today?
      errors.add(:delivery_at, "can't on current date")
    end
  end

  def delivary_date_cannot_be_in_the_past
    if delivery_at.present? && delivery_at < Time.current
      errors.add(:delivery_at, "can't be in the past")
    end
  end

  def cutoff_date_cannot_be_in_the_past
    if cutoff_at.present? && cutoff_at < Time.current
      errors.add(:cutoff_at, "can't be in the past")
    end
  end

  def runningmenu_validate_cutoffs
    if self.activation_at.present? && self.cutoff_at.present? && self.delivery_at.present? && self.admin_cutoff_at.present?
      if self.activation_at > self.cutoff_at
        if (self.created_from_frontend || self.updated_from_frontend) && self.address.addressable.enable_marketplace && !self.address.addressable.enable_saas && self.pickup?
          errors.add(:base, "Its too late to order from this restaurant for tomorrow. Please reach out to us if you need assistance with last minute orders.")
        else
          errors.add(:activation_at, "can't be after cutoff at date & time")
        end
      end

      if self.cutoff_at > self.admin_cutoff_at
        errors.add(:cutoff_at, "can't be after admin cutoff date & time")
      end

      if self.admin_cutoff_at > self.delivery_at
        errors.add(:admin_cutoff_at, "can't be after delivery date & time")
      end
    end
  end

  def admin_cutoff_date_cannot_be_in_the_past
    if admin_cutoff_at.present? && admin_cutoff_at < Time.current
      errors.add(:admin_cutoff_at, "can't be in the past")
    end
  end

  def set_company
    self.company_id = self.address.addressable.id
  end

  def set_delivery_type
    self.delivery_type = Runningmenu.delivery_types["delivery"] if self.addresses.last.enable_self_service
  end

  # def self.fleet_create_task
  #   puts "OnFleet task: Start"
  #   runningmenus = Runningmenu.approved.where(cutoff_at: Time.current.beginning_of_minute - 10.minutes..(Time.current - 1.minute).end_of_minute)
  #   OnfleetTaskJob.perform_later(runningmenus.pluck(:id).join(","), true)
  #   puts "OnFleet task: End"
  # end

  # def self.fleet_update_task
  #   runningmenus = Runningmenu.approved.where(admin_cutoff_at: Time.current.beginning_of_minute - 10.minutes..(Time.current - 1.minute).end_of_minute)
  #   runningmenus.each do |runningmenu|
  #     OnfleetTaskJob.perform_later(runningmenu, false)
  #   end
  # end

  def set_driver_at_onfleet
    if self.driver.present?
      if self.pickup_task_id.present?
        begin
          task = Onfleet::Task.update(self.pickup_task_id, {worker: self.driver.worker_id})
        rescue StandardError => e
          puts "Could not find pickup task with id #{self.pickup_task_id} and runningmenu #{self.id}"
        end
      end
      if self.task_id.present?
        begin
          task = Onfleet::Task.update(self.task_id, {worker: self.driver.worker_id})
        rescue StandardError => e
          puts "Could not find Dropoff task with id #{self.task_id} and runningmenu #{self.id}"
        end
      end
      self.addresses.each do |address|
        address_runningmenu = AddressesRunningmenu.find_by(address_id: address.id, runningmenu_id: self.id)
        if address_runningmenu.restaurant_task_id.present?
          begin
            task = Onfleet::Task.update(address_runningmenu.restaurant_task_id, {worker: self.driver.worker_id})
          rescue StandardError => e
            puts "Could not find Restaurant pickup task with id #{address_runningmenu.restaurant_task_id} and runningmenu #{self.id}"
          end
        end
      end
    end
  end

  def self.four_pm_day_before_delivery
    restaurant_addresses = RestaurantAddress.active.joins(:runningmenus, :restaurant).where("TO_CHAR(NOW() AT TIME ZONE restaurants.time_zone, 'HHam') = ? AND DATE(runningmenus.delivery_at AT TIME ZONE restaurants.time_zone) = DATE(NOW() AT TIME ZONE restaurants.time_zone + INTERVAL '1 day')", '04pm')
    restaurant_addresses.each do |rest_address|
      time_zone = rest_address.addressable.time_zone
      items = rest_address.runningmenus.approved.where("DATE(runningmenus.delivery_at AT TIME ZONE '#{time_zone}') = DATE(NOW() AT TIME ZONE '#{time_zone}' + INTERVAL '1 day')").count
      TwilioSmsService.call(nil, rest_address.id, 'before_delivery') if rest_address.contact_numbers.present? && items > 0
    end
    meetings = Runningmenu.approved.joins(:company, :driver).where("TO_CHAR(NOW() AT TIME ZONE companies.time_zone, 'HHam') = ? AND DATE(runningmenus.delivery_at AT TIME ZONE companies.time_zone) = DATE(NOW() AT TIME ZONE companies.time_zone + INTERVAL '1 day')", '04pm')
    meetings.group_by{|m| m.driver_id}.each do |driver_id, schedulers|
      Driver.find(driver_id).four_pm_day_before_delivery(schedulers.collect{|m| m.delivery_at_timezone.strftime('%a. %b %d') })
    end
  end

  def self.seven_am_day_of_delivery
    restaurant_addresses = RestaurantAddress.active.joins(:runningmenus, :restaurant).where("TO_CHAR(NOW() AT TIME ZONE restaurants.time_zone, 'HHam') = ? AND DATE(runningmenus.delivery_at AT TIME ZONE restaurants.time_zone) = DATE(NOW() AT TIME ZONE restaurants.time_zone)", '07am')
    restaurant_addresses.each do |rest_address|
      time_zone = rest_address.addressable.time_zone
      items = rest_address.runningmenus.approved.where("DATE(runningmenus.delivery_at AT TIME ZONE '#{time_zone}') = DATE(NOW() AT TIME ZONE '#{time_zone}')").count
      TwilioSmsService.call(nil, rest_address.id, 'on_delivery') if rest_address.contact_numbers.present? && items > 0
    end
    meetings = Runningmenu.approved.joins(:company, :driver).where("TO_CHAR(NOW() AT TIME ZONE companies.time_zone, 'HHam') = ? AND DATE(runningmenus.delivery_at AT TIME ZONE companies.time_zone) = DATE(NOW() AT TIME ZONE companies.time_zone)", '07am')
    meetings.group_by{|m| m.driver_id}.each do |driver_id, schedulers|
      Driver.find(driver_id).seven_am_day_of_delivery(schedulers.collect{|m| m.delivery_at_timezone.strftime('%a. %b %d') })
    end
  end

  def self.seven_pm_daily
    restaurant_addresses = RestaurantAddress.active.joins(:runningmenus, :restaurant).where("TO_CHAR(NOW() AT TIME ZONE restaurants.time_zone, 'HHpm') = ?", '07pm').pluck(:id).uniq
    address_ids = restaurant_addresses.join(',') rescue []
    unless address_ids.blank?
      restaurant_admins = RestaurantAdmin.active.joins(:addresses_vendor).where("addresses_vendors.address_id IN (#{address_ids})").uniq
      restaurant_admins.each do |restaurant_admin|
        admin_addresses = []
        current_admin_email = restaurant_admin.email
        admin_addresses = restaurant_admin.addresses_vendor.where(address_id: restaurant_addresses, user_id: restaurant_admin.id).pluck(:address_id).uniq
        start_of_week = Time.current.in_time_zone(restaurant_admin.time_zone).beginning_of_day.utc.to_s(:db)
        end_of_week =  (Time.current + 6.days).in_time_zone(restaurant_admin.time_zone).at_end_of_day.utc.to_s(:db)
        sql = "SELECT * FROM sp_restaurant_orders( p_current_user_id := #{restaurant_admin.id}, p_start_date := '#{start_of_week}', p_end_date := '#{end_of_week}', p_address_ids := '#{admin_addresses.join(',')}')"
        result = ActiveRecord::Base.connection.exec_query(sql)
        result = result.first["sp_restaurant_orders"]
        if result.present?
          meetings = JSON.parse(result)
          meetings= meetings.group_by { |m| m["pickup"].to_date }.transform_values do |meeting|
            meeting.group_by { |meeting| meeting["restaurant_name"] }
          end
          email = ScheduleMailer.upcoming_orders(meetings, admin_addresses, restaurant_admin)
          email_log = EmailLog.new(sender: email.from.first, subject: email.subject, recipient: current_admin_email, body: Base64.encode64(email.body.raw_source))
          email_log.save!
        else
          puts "No Orders Found"
        end
      end
    end
  end

end
