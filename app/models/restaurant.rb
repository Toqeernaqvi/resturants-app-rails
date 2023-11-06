class Restaurant < ApplicationRecord
  include Indexable
  #acts_as_paranoid

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }
  has_many :orders, dependent: :destroy 
  has_one :gmenu_breakfast
  has_one :gmenu_dinner
  has_one :gmenu_lunch
  has_many :addresses, as: :addressable, dependent: :destroy
  has_many :cuisines_restaurants
  has_many :cuisines, through: :cuisines_restaurants
  has_many :gmenus, dependent: :destroy
  has_many :ratings

  has_many :restaurant_billings
  accepts_nested_attributes_for :addresses, allow_destroy: true
  validates :time_zone, presence: true
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :time_zone, presence: true

  after_create :create_gmenu
  enum status: [:active, :deleted]
  enum parent_status: [:active, :deleted], _prefix: :parent_status
  after_save :update_dependents_statuses, if: lambda{|r| r.status_changed?}
  before_validation :whitespace_strip

  searchkick callbacks: false, word_start: [:name]
  scope :search_import, -> { where(status: :active) }
  after_commit :index_elasticsearch
  after_commit :reindex_restaurant_address

  def reindex_restaurant_address
    begin
      self.addresses.active.each do |add|
        RestaurantAddressReindexJob.perform_later(add.id)
      end
    rescue ArgumentError => e
      puts e
      return
    end
  end

  def should_index?
    status # only index active records
  end

  ransacker :menu_type, formatter: proc {|value|
    results = Restaurant.joins(:addresses => ("menu_"+value.downcase).to_sym).uniq&.pluck(:id)
    results = results.present? ? results : nil
   } do |parent|
    parent.table[:id]
  end

  ransacker :marketplace, formatter: proc {|value|
    results = Restaurant.joins(:addresses).where(addresses: {enable_marketplace: value}).uniq&.pluck(:id)
    results = results.present? ? results : nil
   } do |parent|
    parent.table[:id]
  end

  def whitespace_strip
    self.name = self.name.strip
  end


  # def as_json(options = nil)
  #   super({ only: [:name, :contacts, :details] }.merge(options || {}))
  # end
  def create_gmenu
    self.gmenus.create
  end

  def update_dependents_statuses
    # self.gmenus.each do |gmenu|
    #   if gmenu.active?
    #     gmenu.deleted!
    #   else
    #     gmenu.active!
    #   end
    # end

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

  def quickbooks_identity(setting, access_token)
    begin
      service = Quickbooks::Service::Vendor.new
      service.company_id = setting.realmid
      service.access_token = access_token
      # restaurant = service.find_by(:given_name, self.name)
      # restaurant = service.find_by(:display_name, self.name) unless restaurant.first.present?
      util = Quickbooks::Util::QueryBuilder.new
      clause1 = util.clause("GivenName", "=", self.name)
      clause2 = util.clause("DisplayName", "=", self.name)
      restaurant = service.query("SELECT * FROM Vendor WHERE #{clause1}")
      restaurant = service.query("SELECT * FROM Vendor WHERE #{clause2}") unless restaurant.first.present?
      if restaurant.first.present?
        return restaurant.first.id
      else
        restaurant = Quickbooks::Model::Vendor.new
        restaurant.given_name = self.name
        restaurant.middle_name = self.name+self.id.to_s
        restaurant.display_name = self.name
        created_restaurant = service.create(restaurant)
        puts "###################################################### Created Vendor id is: "+created_restaurant.id.to_s
        return created_restaurant.id
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
    end
  end

  ransacker :commission_greater_than_0, formatter: proc {|value|
    results =  RestaurantAddress.where("discount_percentage > ?", 0.0).pluck(:addressable_id).uniq
    results = results.present? ? results.uniq : nil
  } do |parent|
    parent.table[:id]
  end

end
