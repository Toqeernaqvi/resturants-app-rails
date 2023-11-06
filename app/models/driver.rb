class Driver < ApplicationRecord
  enum status: [:active, :deleted]
  validates_format_of :phone_number,
  :with => /\A[0-9]{3}-[0-9]{3}-[0-9]{4}\Z/,
  :message => "Phone numbers must be in xxx-xxx-xxxx format.", unless: lambda {|d| d.saved_change_to_status?}
  validates :first_name, :last_name, :email, :phone_number, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a 'example@example.com ' " }
  after_validation :add_worker_to_onfleet, if: lambda {|d| d.new_record?}
  after_update :update_onfleet_worker, unless: lambda {|d| d.saved_change_to_status?}
  after_save :toggle_driver_activeness, if: lambda {|d| d.saved_change_to_status?}
  after_save :set_driver_team, if: lambda {|d| d.saved_change_to_restaurant_address_id? && !d.saved_change_to_id? }
  after_create :set_shifts, if: lambda {|d| d.restaurant_address.present? }
  before_save :destroy_old_shifts, if: lambda { |d| d.will_save_change_to_restaurant_address_id? }
  mount_uploader :image, DriverImageUploader
  has_many :driver_shifts
  has_many :monday_shifts
  has_many :tuesday_shifts
  has_many :wednesday_shifts
  has_many :thursday_shifts
  has_many :friday_shifts
  has_many :saturday_shifts
  has_many :sunday_shifts
  belongs_to :restaurant_address, optional: true
  accepts_nested_attributes_for :monday_shifts, :tuesday_shifts, :wednesday_shifts, :thursday_shifts, :friday_shifts, :saturday_shifts, :sunday_shifts, allow_destroy: true

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  attr_accessor :created_from_frontend, :updated_from_frontend

  def number_at_onfleet
    Onfleet::Worker.get(self.worker_id).phone rescue ("+1"+self.phone_number.gsub("-",""))
  end

  def sms_broadcast(message)
    from = ENV["SMS_FROM"]
    # to = ENV["SMS_TO"]
    to = number_at_onfleet
    recent_message = message
    begin
      # @client = Twilio::REST::Client.new(ENV["TWILIO_TEST_ACCOUNT_SID"], ENV["TWILIO_TEST_AUTH_TOKEN"])
      # @client = Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
      sms = $twilio_client.messages.create(body: message,from: from,to: to)
      recent_message = "<div class='me'><span>me: </span>#{message}</div>"
    rescue => e
      puts e.message
      recent_message = "<div class='me'><span>me: </span>Message not sent #{e.message}</div>"
    end
    ActionCable.server.broadcast("drivers_#{self.id}_channel", {message: recent_message, driver_id: self.id})
  end

  def add_worker_to_onfleet
    puts "OnFleet Worker Create Start"
    if !self.errors.present?
      begin
        ph_no = "+1#{self.phone_number.remove('-')}"
        presence = false
        workers = Onfleet::Worker.list
        workers.each do |worker|
          if worker.phone == ph_no
            driver_existence = Driver.find_by_worker_id(worker.id)
            if driver_existence.present?
              errors.add(:phone_number, "Driver exists by this phone number")
              presence = true
            else
              Onfleet::Worker.update(worker.id, {name: self.name, email: self.email, vehicle: {type: "CAR", description: self.car, color: self.car_color, licensePlate: self.car_licence_plate} })
              self.worker_id = worker.id
              presence = true
            end
          end
        end
        unless presence
          worker = Onfleet::Worker.create(self.worker_attributes_set)
          self.worker_id = worker.id
        end
      rescue StandardError => e
        errors.add(:phone_number, "Driver failed to save due to #{e.message}")
        puts " OnFleet Worker: #{e.message}"
      end
    end
    puts "OnFleet Worker Create End"
  end

  def update_onfleet_worker
    puts "OnFleet Worker Update Start"
    begin
      Onfleet::Worker.update(self.worker_id, {name: self.name, email: self.email, vehicle: {type: "CAR", description: self.car, color: self.car_color, licensePlate: self.car_licence_plate} })
    rescue StandardError => e
      errors.add(:first_name, "Driver failed to save due to #{e.message}")
      puts " OnFleet Worker: #{e.message}"
    end
    puts "OnFleet Worker Update End"
  end

  def set_driver_team
    if self.worker_id.present?
      Onfleet::Worker.delete(self.worker_id) rescue nil
      self.update_column(:worker_id, nil)
      self.update_column(:onfleet_team_id, nil)
      begin
        worker = Onfleet::Worker.create(self.worker_attributes_set)
        if worker.present?
          self.worker_id = worker.id
          self.save
        end
      rescue StandardError => e
        errors.add(:phone_number, "Driver failed to save due to #{e.message}")
        puts " OnFleet Worker: #{e.message}"
      end
    end
  end

  def toggle_driver_activeness
    if self.deleted? && self.worker_id.present?
      Onfleet::Worker.delete(self.worker_id) rescue nil
      self.update_column(:worker_id, nil)
    else
      begin
        worker = Onfleet::Worker.create(self.worker_attributes_set)
        if worker.present?
          self.worker_id = worker.id
          self.save
        end
      rescue StandardError => e
        errors.add(:phone_number, "Driver failed to save due to #{e.message}")
        puts " OnFleet Worker: #{e.message}"
      end
    end
  end

  def get_or_create_team_id
    team_id = ENV["ONFLEET_DEFAULT_TEAM_ID"]
    unless self.restaurant_address_id.nil?
      if self.restaurant_address.onfleet_team_id.nil?
        begin
          team = Onfleet::Team.create({name: self.restaurant_address.name})
          self.restaurant_address.update_columns(onfleet_team_id: team.id)
          team_id = team.id
        rescue StandardError => e
          errors.add(:phone_number, "Driver failed to save due to #{e.message}")
          puts " OnFleet Worker: #{e.message}"
        end
      else
        team_id = self.restaurant_address.onfleet_team_id
      end
    end
    if self.new_record?
      self.onfleet_team_id = team_id
    else
      self.update_columns(onfleet_team_id: team_id)
    end
    team_id
  end

  def worker_attributes_set
    # teams = Onfleet::Team.list
    # team_id = teams.last.id
    team_id = self.get_or_create_team_id
    org = Onfleet::Organization.get
    { organization: org.id, name: self.name, email: self.email, phone: self.phone_number, teams: [team_id], vehicle: { type: "CAR", description: self.car, color: self.car_color, licensePlate: self.car_licence_plate} }
  end

  def name
    if first_name.present? || last_name.present?
      first_name.to_s + ' ' + last_name.to_s
    end
  end

  def destroy_old_shifts
    self.driver_shifts.where.not(id: nil).destroy_all
  end

  def self.available_on(delivery_at, pickup_at, delivery_type, address_id, address_ids)
    company = CompanyAddress.find_by_id(address_id)&.addressable
    time_zone = company.present? ? company.time_zone : 'US/Pacific'
    delivery_at = delivery_at.in_time_zone(time_zone)
    pickup_time = pickup_at.in_time_zone(time_zone)
    delivery_day, pickup_day = delivery_at.strftime("%A"), pickup_time.strftime("%A")
    p_params = "p_delivery_at := '#{delivery_at}', p_delivery_day := '#{delivery_day}', p_pickup_time := '#{pickup_time}', p_pickup_day := '#{pickup_day}', p_delivery_type := '#{delivery_type}'"
    if address_ids.present? && delivery_type == 'delivery'
      p_params += ", p_address_ids := '#{address_ids}'"
    end
    drivers = Driver.find_by_sql("SELECT * FROM sp_drivers_list(#{p_params})")
  end

  def as_json(options = nil)
    super({ only: [:id, :car, :car_color, :car_licence_plate], methods: [:name, :driver_image, :ph_number] }.merge(options || {}))
  end

  def ph_number
    self.phone_number.present? ? '1-' + self.phone_number : nil
  end

  def driver_image
    if self.image.present?
      self.image.url
    end
  end

  def create_shifts(shifts)
    shifts.where(:closed=>false).each do |shift|
      DriverShift.create!(driver_id: self.id, label: shift.label, start_time: shift.start_time, end_time: shift.end_time)
    end
  end

  def set_shifts
    if created_from_frontend
      create_shifts(restaurant_address.monday_shifts)
      create_shifts(restaurant_address.tuesday_shifts)
      create_shifts(restaurant_address.wednesday_shifts)
      create_shifts(restaurant_address.thursday_shifts)
      create_shifts(restaurant_address.friday_shifts)
      create_shifts(restaurant_address.saturday_shifts)
      create_shifts(restaurant_address.sunday_shifts)
    end
  end

  def scheduled_meeting meeting
    puts "Driver ##{number_at_onfleet}"
    if number_at_onfleet.present?
      message = "You have been assigned a Chowmill delivery on #{meeting.delivery_at_timezone.strftime('%a. %b %d')}. Please contact Chowmill with any concerns."
      generate_sms_log message
    else
      puts "Driver number not found"
    end
  end

  def cancelled_meeting meeting
    puts "Driver ##{number_at_onfleet}"
    if number_at_onfleet.present?
      puts "Driver #{self.id} sms start for cancelled_meeting #{meeting.id}"
      deliveries = Runningmenu.approved.where("driver_id = ? AND delivery_at > ?", self.id, Time.current).collect{|m| m.delivery_at_timezone.strftime('%a. %b %d') }
      message = "Sorry, you are no longer scheduled for Chowmill delivery on #{meeting.delivery_at_timezone.strftime('%a. %b %d')}."
      message += " You still have #{deliveries.count} other #{deliveries.count > 1 ? 'deliveries' : 'delivery'} for Chowmill on #{deliveries.uniq.join(", ")}" if deliveries.count > 0
      generate_sms_log message
    else
      puts "Driver number not found"
    end
  end

  def four_pm_day_before_delivery deliveries
    puts "Driver ##{number_at_onfleet}"
    if number_at_onfleet.present?
      message = "Reminder: You have #{deliveries.count} Chowmill deliveries tomorrow #{deliveries.uniq.join(", ")}. Please contact Chowmill with any concerns."
      generate_sms_log message
    else
      puts "Driver number not found."
    end
  end

  def seven_am_day_of_delivery deliveries
    puts "Driver ##{number_at_onfleet}"
    if number_at_onfleet.present?
      message = "Reminder: You have #{deliveries.count} Chowmill deliveries today #{deliveries.uniq.join(", ")}. Please contact Chowmill with any concerns."
      generate_sms_log message
    else
      puts "Driver number not found."
    end
  end

  def generate_sms_log message
    SmsLog.create(from: ENV["SMS_FROM"], to: number_at_onfleet, body: message, name: self.name, restaurant_id: self.restaurant_address&.addressable_id, restaurant_address_id: self.restaurant_address_id)
  end

end
