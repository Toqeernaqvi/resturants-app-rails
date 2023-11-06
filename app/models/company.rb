class Company < ApplicationRecord
  #acts_as_paranoid

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  has_many :runningmenus, dependent: :destroy

  has_many :addresses, as: :addressable, dependent: :destroy
  accepts_nested_attributes_for :addresses#, allow_destroy: true

  has_many :addresses_active, -> {where "parent_status = #{CompanyAddress.parent_statuses[:active]} AND status= #{CompanyAddress.statuses[:active]}"}, class_name: 'CompanyAddress', as: :addressable, dependent: :destroy
  accepts_nested_attributes_for :addresses_active

  has_many :company_admins, dependent: :destroy
  has_many :company_admins_active, -> {where "status = #{User.statuses[:active]}"}, class_name: 'CompanyAdmin'
  has_many :company_users, dependent: :destroy
  accepts_nested_attributes_for :company_admins, allow_destroy: true
  accepts_nested_attributes_for :company_admins_active, allow_destroy: true

  has_many :fields, dependent: :destroy
  accepts_nested_attributes_for :fields, allow_destroy: true

  has_many :fields_active, -> {where "status = #{Field.statuses[:active]}"}, class_name: 'Field', dependent: :destroy
  accepts_nested_attributes_for :fields_active, allow_destroy: true

  has_many :orders
  has_many :payment_logs
  has_one :billing

  has_many :childs, class_name: "Company", foreign_key: "parent_company_id"
  belongs_to :parent_company, class_name: "Company", foreign_key: "parent_company_id", optional: true

  accepts_nested_attributes_for :billing

  has_many :staffs, -> {where 'office_admin_id IS NOT NULL'}, class_name: 'User'
  has_many :users, dependent: :destroy

  has_many :ban_addresses, dependent: :destroy
  has_many :locations, through: :ban_addresses, source: :address
  has_many :invoices, :inverse_of => :company
  has_many :recurring_schedulers

  validates :name, :image, :time_zone, presence: true
  validates :reduced_markup, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}, unless: lambda {|c| c.will_save_change_to_status? || c.will_save_change_to_parent_status?}
  validates :addresses_active, :length => { :minimum => 1 }, unless: lambda {|c| c.will_save_change_to_status? || c.will_save_change_to_parent_status?}
  # validates :entree, :appetizers, :dessert, :sides, numericality: {greater_than_or_equal_to: 0, less_than: 100 }
  # validates :addresses, :length => { :minimum => 1 }, unless: lambda {|c| c.will_save_change_to_status? || c.will_save_change_to_parent_status?}
  # validates_length_of :user_meal_budget, :markup, :copay_amount, in: 1..5
  validates :user_meal_budget, :markup, :copay_amount, :buffet_addons_markup, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 99999 }, unless: lambda {|c| c.will_save_change_to_status? || c.will_save_change_to_parent_status?}

  validate :prevent_parent_of_parent, if: lambda{|c| c.parent_company_id.present? && c.childs.present?}

  before_save :check_reduced_markup_and_copay
  after_save :update_user_status, if: lambda{|c| c.status_changed?}

  after_save :update_budget_in_reports, if: lambda { |c| c.user_meal_budget_changed? }

  enum status: [:active, :deleted]
  enum parent_status: [:active, :deleted], _prefix: :parent_status

  mount_uploader :image, LogoUploader

  def as_json(options = nil)
    super({ only: [
      :id,
      :name,
      :user_meal_budget,
      :markup,
      :reduced_markup,
      :reduced_markup_check,
      :user_copay,
      :copay_amount,
      :show_remaining_budget,
      :enable_grouping_orders,
      :image,
      :buffet_addons_markup,
      :enable_marketplace,
      :enable_saas,
      :time_zone,
      :parent_company_id
    ], methods: [:budget] }.merge(options || {}))
  end

  def prevent_parent_of_parent
    errors.add(:parent_company_id, "This company is parent of other companies")
  end

  def show_remaining_budget
    self.show_remaining_budget?
  end

  def budget
    self.user_meal_budget + ((self.reduced_markup_check && self.reduced_markup > 0 && !self.enable_saas) ? self.markup * self.reduced_markup / 100 : 0)
  end

  def update_budget_in_reports
    RepBudgetAnalysis.where(company_id: self.id).update_all(budget: self.user_meal_budget)
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
        customer.given_name = self.name
        customer.middle_name = self.name+self.id.to_s
        customer.display_name = self.name
        created_customer = service.create(customer)
        puts "###################################################### Created Customer id is: "+created_customer.id.to_s
        return created_customer.id
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
    end
  end

  private

  def check_reduced_markup_and_copay
    unless self.reduced_markup_check?
      self.reduced_markup = 0
    end

    unless self.user_copay?
      self.copay_amount = 0
    end
  end

  def update_user_status
    self.users.each do |user|
      if self.deleted?
        user.deleted!
      else
        if user.parent_status_deleted?
          user.deleted!
        else
          user.active!
        end
      end
    end

    runningmenus = Runningmenu.where('company_id = ? AND delivery_at > ?', self.id, Time.current)
    if runningmenus.present?
      runningmenus.each do |runningmenu|
        if self.deleted? && runningmenu.approved? || runningmenu.pending?
          runningmenu.update_column(:status, Runningmenu.statuses[:cancelled])
          runningmenu.send_email_for_cancel_schedule
          runningmenu.orders.each do |order|
            order.update_column(:status, Order.statuses[:cancelled])
          end
        elsif self.active? && runningmenu.cancelled? && runningmenu.parent_status_active?
          if runningmenu.addresses.active.present?
            runningmenu.update_columns(status: Runningmenu.statuses[:approved], approved_at: Time.current)
            runningmenu.init_notify_restaurant_job
          else
            runningmenu.update_column(:status, Runningmenu.statuses[:pending])
          end
          runningmenu.orders.each do |order|
            if order.parent_status_deleted?
              order.update_column(:status, Order.statuses[:cancelled])
            else
              order.update_column(:status, Order.statuses[:active])
            end
          end
        end
      end
    end
    addresses = self.addresses.where(status: [:active, :deleted])
    addresses.each do |address|
      if self.deleted?
        address.deleted!
      else
        if address.parent_status_deleted?
          address.deleted!
        else
          address.active!
        end
      end
    end
  end
end
