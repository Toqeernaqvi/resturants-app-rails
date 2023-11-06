class Order < ApplicationRecord
  #acts_as_paranoid
  has_paper_trail versions: { scope: -> { order("id desc") } }, if: lambda {|o| (Time.current > (o.runningmenu.approved_at + ENV["MEETING_EMAILS_INTERVAL"].to_i.minutes) && Time.current < o.runningmenu.admin_cutoff_at) }
  
  GROUP_LIMIT = 42
  
  attr_accessor :skip_after_save_update_user_orders, :share_meeting_transaction_id, :red_type, :stripe_token

  # enum order_type: [:dont_care, :lunch, :dinner, :breakfast]
  enum status: [:active, :cancelled]
  enum parent_status: [:active, :deleted], _prefix: :parent_status

  belongs_to :latest_version, optional: true, foreign_key: :latest_version_id, class_name: 'PaperTrail::Version'
  # belongs_to :address
  belongs_to :restaurant_address, optional: true
  belongs_to :dishsize, optional: true
  # belongs_to :company
  belongs_to :fooditem
  belongs_to :restaurant, optional: true
  belongs_to :share_meeting, optional: true
  belongs_to :runningmenu
  # delegate :company, to: :runningmenu
  has_one :company, through: :runningmenu
  belongs_to :user
  belongs_to :invoice, optional: true
  belongs_to :restaurant_billing, optional: true
  belongs_to :guest, optional: true
  
  has_many :orderfields
  has_many :optionsets_orders, dependent: :destroy
  has_many :optionsets, through: :optionsets_orders
  has_and_belongs_to_many :payment_logs
  has_many :order_change_logs

  accepts_nested_attributes_for :optionsets_orders, allow_destroy: true
  accepts_nested_attributes_for :orderfields
  accepts_nested_attributes_for :guest, reject_if: :all_blank

  before_validation :delivery_date_cannot_be_from_the_future, :on => :update, unless: lambda{|o| o.rating_changed?}
  before_validation :calculate_order_totalprice, if: lambda{|o| !(o.rating_changed? || (o.status_changed? || o.saved_change_to_status?) || (o.parent_status_changed? || o.saved_change_to_parent_status?) ) }
  validate :validate_stripe_token
  validate :validate_stripe_customer

  # validate :set_share_meeting_user_price, if: lambda{|o| !o.skip_after_save_update_user_orders && o.share_meeting.present? }
  #validate :order_can_be_unique_for_each_user
  validate :orders_within_budget
  validate :validate_fooditems  
  validates :quantity, numericality: {greater_than_or_equal_to: 1}
  validates :discount, numericality: {greater_than_or_equal_to: 0}
  validate :check_order_timings, if: lambda{|o| !(o.rating_changed? || o.will_save_change_to_status? || o.will_save_change_to_parent_status? || o.will_save_change_to_cancelled_time? ) }
  validates_length_of :quantity, in: 1..5
  validates_presence_of :dishsize, if: lambda {|o| o.runningmenu.buffet?}
  # validate :verify_serve_count, if: lambda{|o| o.runningmenu.buffet?}
  # validate :per_section_orders, on: :create, if: lambda{|o| o.runningmenu.buffet?}

  # before_save :set_rating, if: lambda{|c| c.rating_changed?}
  # before_save :init_restaurant_payout_calculation, if: :will_save_change_to_food_price_total?
  before_save :before_save_order
  before_create :initialize_attributes
  # after_create :share_meeting_log_generate, if: lambda{|o| o.share_meeting.present? && o.paid? }
  after_save :after_save_order
  after_create :create_order_change_log
  after_update :update_order_change_log
  # after_save :update_user_orders, if: lambda { |o| !o.skip_after_save_update_user_orders && (o.user.company_user? || o.share_meeting.present?) && (o.status_changed? || o.saved_change_to_status? || o.total_price_changed? || o.saved_change_to_total_price?) }

  # ransacker :company_id, formatter: proc {|value|
  #   results = Order.joins(:runningmenu).where('runningmenus.company_id = ?', value.to_i).pluck(:id)
  #   results = results.present? ? results : nil
  #  } do |parent|
  #   parent.table[:id]
  # end

  # ransacker :address_id, formatter: proc {|value|
  #   results = Order.joins(:runningmenu).where('runningmenus.address_id = ?', value.to_i).pluck(:id)
  #   results = results.present? ? results : nil
  #  } do |parent|
  #   parent.table[:id]
  # end

  def before_save_order
    set_rating if self.rating_changed?
    init_restaurant_payout_calculation if self.will_save_change_to_food_price_total?
  end

  def after_save_order
    update_user_orders if !self.skip_after_save_update_user_orders && (self.user.company_user? || self.user.company_manager? || self.share_meeting.present?) && (self.status_changed? || self.saved_change_to_status? || self.total_price_changed? || self.saved_change_to_total_price?)
    send_confirmation if self.active? && self.runningmenu.company.present? && (self.user.company_user? || self.user.unsubsidized_user? || self.user.company_manager? || self.share_meeting.present?)
    refund_stripe_customer if (self.runningmenu.company.present? && self.saved_change_to_status? && self.cancelled?) && (self.user.company_user? || self.user.unsubsidized_user? || self.user.company_manager? || self.share_meeting.present?)
  end

  def send_confirmation
    if (self.runningmenu.per_user_copay? || self.user.unsubsidized_user?) && self.user_paid > 0 && self.saved_change_to_user_paid?
      self.share_meeting.present? ? self.share_meeting.charge_customer(self.id) : self.user.charge_customer(self.id)
    elsif (self.runningmenu.per_user_copay? || self.user.unsubsidized_user?) && self.user_paid <= 0 && self.saved_change_to_user_paid? && self.user_paid_was > 0
      refund = self.refund_stripe
    elsif self.saved_change_to_total_price?
      self.send_confirmation_email
    end
  end

  def refund_stripe_customer
    refund = nil
    if (self.runningmenu.per_user_copay? && self.user_paid > 0)
      refund = self.refund_stripe
    end
    self.send_confirmation_email(refund)
  end

  def refund_stripe
    if self.share_meeting.present?
      payment_log = self.payment_logs.stripe.success.where(email: self.share_meeting.email).last
    else
      payment_log = self.payment_logs.stripe.success.where(email: self.user.email, user_id: self.user_id).last
    end
    if payment_log.present? && payment_log.amount > 0
      result = Stripe::Refund.create({
        charge: payment_log.transaction_id,
      })
      if result.present? && result.status == "succeeded"
        payment_log.refunded!
      end
      result
    end
  end

  def send_confirmation_email(refund=nil)
    email = OrderMailer.order_placed(self, refund)
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  end

  # def verify_serve_count
  #   if (self.new_record? ? (self.runningmenu.orders.active.sum(:total_price) + self.total_price) : (self.runningmenu.orders.active.where.not(id: self.id).sum(:total_price) + self.total_price)) > (self.runningmenu.buffet_per_user_budget * self.runningmenu.orders_count)
  #     errors.add(:base, "Order count is greater than as per decided.")
  #   end
  # end

  # def per_section_orders
  #   orders_count = self.runningmenu.orders.active.joins(:fooditem => :sections).where('sections.section_type = ?', Section.section_types[self.fooditem.sections.first.section_type]).select('sections.section_type AS section_type, COUNT(sections.section_type) AS section_orders_count').group('sections.section_type')
  #   section_type = self.fooditem.sections.first.section_type
  #   if ["appetizer", "side"].include? section_type
  #     section_type = section_type.pluralize
  #   end
  #   if self.runningmenu[section_type] == 0 || ((orders_count.present? ? orders_count.first.section_orders_count : 0)  >= self.runningmenu[section_type])
  #     errors.add(:base, "You have reached the maximum allowed #{section_type.capitalize.pluralize}. Please remove one of the #{section_type.capitalize.pluralize} before trying to add another.")
  #   end
  # end

  def self.cloning(runningmenu, order_ids, user_id)
    errors = []
    Order.where(:id=>order_ids).each do |order|
      if order.optionsets_orders.blank?
        new_order = Order.new(order.attributes.slice("restaurant_id","restaurant_address_id","company_id","address_id","dishsize_id","fooditem_id","quantity").merge({:runningmenu_id => runningmenu.id, :user_id => user_id}))
        errors << new_order.errors.full_messages[0] unless new_order.save
      else
        new_order = order.attributes.slice("restaurant_id","restaurant_address_id","company_id","address_id","dishsize_id","fooditem_id","quantity").merge({"runningmenu_id" => runningmenu.id, "user_id" => user_id})
        sets_hash = {}
        order.optionsets_orders.each_with_index do |optionset_order, index|
           sets_hash[index.to_s]={"optionset_id"=>optionset_order.optionset_id, "required"=>optionset_order.required, "options_orders_attributes"=>optionset_order.options_orders.collect{|c| {"option_id"=>c.option_id}}}
        end
        options_hash = {"optionsets_orders_attributes"=>sets_hash}
        new_order_obj = Order.new(new_order.merge(options_hash))
        errors << new_order_obj.errors.full_messages[0] unless new_order_obj.save
      end
    end
    errors
  end

  def update_user_orders
    orders = self.share_meeting.present? ? self.share_meeting.orders.active.where(runningmenu_id: self.runningmenu_id) : self.user.orders.active.where(runningmenu_id: self.runningmenu_id)
    orders.each do |o|
      o.skip_after_save_update_user_orders = true
      o.save
    end
  end

  def check_order_timings
    if self.runningmenu.delivery_at < Time.current
      errors[:base] << "Scheduler delivery has been passed order processing cannot happen."
    elsif (self.user.company_user? || self.user.company_manager? || self.share_meeting_id.present?) && self.runningmenu.cutoff_at < Time.current
      errors[:base] << "Scheduler cutoff has been passed order processing cannot happen."
    elsif self.user.company_admin? && !self.share_meeting_id.present? && self.runningmenu.admin_cutoff_at < Time.current
      errors[:base] << "Scheduler admin Cutoff has been passed order processing cannot happen."
    end
  end

  def validate_stripe_token
    if (self.runningmenu.per_user_copay? || self.user.unsubsidized_user?) && self.user_paid > 0 && ( ((self.user.company_user? || self.user.company_manager? || self.user.unsubsidized_user?) && self.user.customer_id.blank?) || (self.share_meeting.present? && self.share_meeting.customer_id.blank?)) && self.stripe_token.blank?
      self.errors.add(:base, "Stripe token not present.")
    elsif self.stripe_token.present? #&& (self.share_meeting.present? ? self.share_meeting.customer_id.blank? : self.user.customer_id.blank?)
      self.user.update_attribute(:stripe_token, self.stripe_token) if (self.user.company_user? || self.user.company_manager? || self.user.unsubsidized_user?)
      self.share_meeting.update_attribute(:stripe_token, self.stripe_token) if self.share_meeting.present?
    end
  end

  def validate_stripe_customer
    if (self.runningmenu.company.present? && ((self.runningmenu.per_user_copay? || self.user.unsubsidized_user?) && self.user_paid > 0)) && ( ((self.user.company_user? || self.user.company_manager? || self.user.unsubsidized_user?) && self.user.profile_completed? && self.user.customer_id.blank?) || (self.share_meeting.present? && self.share_meeting.customer_id.blank?))
      errors.add(:base, "Unable to place order due to missing cc information.")
    end
  end

  def create_order_change_log
    self.order_change_logs.create(order_quantity: self.quantity)
  end

  def update_order_change_log
    if self.saved_change_to_quantity?
      self.order_change_logs.create(order_quantity: self.quantity-self.quantity_was)
    elsif self.saved_change_to_status? && self.active?
      self.order_change_logs.create(order_quantity: self.quantity)
    elsif self.saved_change_to_status? && self.cancelled?
      self.order_change_logs.create(order_quantity: -self.quantity)
    end
  end

  # def set_share_meeting_user_price
  #   user_paid_price = self.share_meeting.user_price + self.user_paid
  #   if user_paid_price > 0 && !self.share_meeting.customer_id.blank?
  #     meeting = self.share_meeting
  #     if meeting.customer_id.present?
  #       result = $gateway.transaction.sale(
  #         :customer_id => meeting.customer_id,
  #         :amount => user_paid_price,
  #         :options => {
  #           :submit_for_settlement => true
  #         }
  #       )
  #       # orders = [self]
  #       if result.success?
  #         puts "Order Processing: Transaction successfully processed"
  #         self.share_meeting_transaction_id = result.transaction.id
  #         # Order.generate_logs(nil, true, orders, "Transaction successfully processed", result.transaction.id, user_paid_price, meeting)
  #         self.payment_status = Order.payment_statuses[:paid]
  #         meeting.update_columns(attempts_count: 0, valid_card: true, payment_status: :paid)
  #       else
  #         errors.add(:base, "Transaction failed due to some reason")
  #       end
  #     else
  #       errors.add(:base, "Transaction failed due to some reason")
  #     end
  #   end
  # end

  # def share_meeting_log_generate
  #   Order.generate_logs(nil, true, [self], "Transaction successfully processed", self.share_meeting_transaction_id, self.share_meeting.user_price + self.user_paid, self.share_meeting)
  #   self.share_meeting.update_column(:user_price, 0)
  # end

  # def order_can_be_unique_for_each_user
  #   if self.new_record? && self.user.company_user? && Order.active.exists?(runningmenu_id: self.runningmenu_id, user_id: self.user.id)
  #     errors.add(:user_id, "has already ordered")
  #   end
  # end

  def orders_within_budget
    if self.new_record? && ((self.user.company_user? || self.user.company_manager?) && !self.runningmenu.per_user_copay? || (self.share_meeting.present? && !self.runningmenu.per_user_copay?))
      user_total_price = self.share_meeting.present? ? self.runningmenu.orders.active.where(share_meeting_id: self.share_meeting_id).sum(:total_price) : self.runningmenu.orders.active.where(user_id: self.user.id).sum(:total_price)
      if user_total_price + self.total_price > self.runningmenu.scheduler_budget
        errors.add(:user_id, "Order out of budget. your budget is #{self.runningmenu.per_meal_budget-user_total_price}")
      end
    end
  end

  def user_paid_with_fee
    amount = ((self.user_paid + 0.30).to_f / (1-0.029).to_f).round(2)
    amount = amount < 0.50 ? 0.50 : amount
  end

  def user_payable_amount
    self.user_markup ? (self.user_price + self.site_price) : self.user_price
  end

  def company_payable_amount
    self.user_markup ? self.company_price : (self.company_price + self.site_price)
  end

  def company_name
    self.runningmenu.company.name
  end

  def init_restaurant_payout_calculation
    if self.restaurant_address.blank?
      self.restaurant_address_id = self.fooditem.menu.address.id
    end
    self.sales_tax_rate = TaxRate.exists?(zip: self.restaurant_address.zip) ? TaxRate.find_by(zip: self.restaurant_address.zip).estimated_combined_rate : 0.0925
    self.sales_tax = sales_tax_rate * self.food_price_total
    if self.restaurant_address.enable_self_service
      self.restaurant_commission = 0.0
      self.restaurant_payout = self.food_price_total + self.sales_tax
    end
    if self.runningmenu.individual?
      unless self.restaurant_address.enable_self_service
        self.restaurant_commission = (self.food_price_total * self.restaurant_address.discount_percentage)/100
        self.restaurant_payout = self.food_price_total - self.restaurant_commission + self.sales_tax
      end
      self.number_of_meals = self.quantity
    else
      unless self.restaurant_address.enable_self_service
        quantity_total = self.runningmenu.orders.active.sum(:quantity)
        food_total = self.runningmenu.orders.active.sum(:food_price_total)
        buffet_commission = (quantity_total >= self.restaurant_address.items_count || food_total >= self.restaurant_address.minimum_discount_price) ? (self.restaurant_address.add_contract_commission ? (self.restaurant_address.discount_percentage + self.restaurant_address.buffet_commission) : self.restaurant_address.buffet_commission) : 0
        self.restaurant_commission = (self.food_price_total * buffet_commission)/100
        self.restaurant_payout = (self.food_price_total - self.restaurant_commission + self.sales_tax )
      end
      self.number_of_meals = self.dishsize.present? ? self.dishsize.serve_count * self.quantity : self.quantity
    end
  end

  def group_view
    self.group.split(",").map{|m| m.split("-")[0].scan(/\d+|[A-Za-z]+/)}.map{|x| x[0]+"-"+x[1]}.join(", ") rescue nil
  end

  def self.get_groups(starting_group, grouping_rows, grouping_columns)
    subgroups = (1..grouping_rows).to_a
    arr = (starting_group..'ZZ').to_a
    groups = []
    arr.each do |a|
      subgroups.each do |n|
        groups += Array.new(grouping_columns, a+n.to_s)
      end
    end
    groups
  end

  def self.fill_groups(groups, counter, orders, grouping_columns)
    # order_group = []
    # orders.each do |order|
    #   (counter+1..counter+order.quantity).each do |i|
    #     order_group << groups[(i-1)]
    #   end
    #   order.update_columns(group: order_group.group_by(&:itself).collect{|c| c[0]+"-"+c[1].count.to_s}.join(","))
    #   order_group = []
    #   counter = counter+order.quantity
    # end

    order_group = []
    indx = (counter+1 > grouping_columns ? 1 : counter+1)
    orders.each do |order|
      (counter+1..counter+order.quantity).each do |i|
        order_group << groups[(i-1)]
      end
      group_str = []
      order_group.group_by(&:itself).each do |a, b|
        b.each do |c|
          group_str << c+"-"+indx.to_s
          indx = indx == grouping_columns ? 1 : indx+1
        end
      end
      # puts group_str.join(", ")
      order.update_columns(group: group_str.join(","))
      # order.update_columns(group: order_group.group_by(&:itself).collect{|c| c[0]+"-"+c[1].count.to_s}.join(","))
      order_group = []
      counter = counter+order.quantity
    end
  end

  def self.assign_groups(runningmenu)
    # runningmenus = runningmenus.joins(:company).where("companies.enable_grouping_orders = ?", true)
    # runningmenus.each do |runningmenu|
    #   orders = runningmenu.orders.active.joins(:user).order("users.first_name ASC, users.last_name ASC")
    #   groups = Order.get_groups('A')
    #   counter = 0
    #   Order.fill_groups(groups, counter, orders)
    # end
    # orders = runningmenu.orders.active.joins(:user).where("disable_grouping_orders = false OR share_meeting_id IS NOT NULL").order("users.first_name ASC, users.last_name ASC")
    orders = runningmenu.orders.active.joins(:user, :fooditem, :restaurant).where("disable_grouping_orders = false OR share_meeting_id IS NOT NULL").order("restaurants.name ASC, fooditems.name ASC, orders.id ASC")
    # orders = []
    # runningmenu.orders.active.joins(:user, :fooditem).where("disable_grouping_orders = false OR share_meeting_id IS NOT NULL").order("fooditems.name ASC").group_by{|o| o.fooditem.name }.each do |name, item_orders|
    #   orders << item_orders
    # end
    groups = Order.get_groups('A', runningmenu.address.grouping_rows, runningmenu.address.grouping_columns)
    counter = 0
    # Order.fill_groups(groups, counter, orders.flatten)
    Order.fill_groups(groups, counter, orders, runningmenu.address.grouping_columns)
  end

  def self.assign_groups_to_orders_after_cutoff(runningmenu)
    # runningmenus = runningmenus.joins(:company).where("companies.enable_grouping_orders = ?", true)
    # runningmenus.each do |runningmenu|
    #   if runningmenu.orders.active.where(:group=>nil).count > 0
    #     orders = runningmenu.orders.active.where(:group=>nil)
    #     max = []
    #     runningmenu.orders.active.pluck(:group).compact.each do |g|
    #       g.split(",").each do |a|
    #         max << a
    #       end
    #     end
    #     if max.blank? && !orders.blank?
    #       groups = Order.get_groups('A')
    #       counter = 0
    #       Order.fill_groups(groups, counter, orders)
    #     else
    #       max_group = max.sort.last.split("-")
    #       group = max_group.first
    #       subgroup = group.last
    #       group_count = max_group.last.to_i
    #       if group_count == 7 && subgroup == "6"
    #         counter = 0
    #         group = group.first.next
    #         groups = Order.get_groups(group)
    #       else
    #         counter = group_count
    #         alpha_group = group.first
    #         subgroups = (subgroup.to_i..6).to_a
    #         groups = []
    #         subgroups.each do |n|
    #           groups += Array.new(7, alpha_group+n.to_s)
    #         end
    #         groups = groups.drop(counter)
    #         groups += Order.get_groups(alpha_group.next)
    #       end
    #       Order.fill_groups(groups, counter, orders)
    #     end
    #   end
    # end
    if runningmenu.orders.active.joins(:user).where("orders.group IS NULL AND (disable_grouping_orders = false OR share_meeting_id IS NOT NULL)").count > 0
      orders = runningmenu.orders.active.joins(:user, :fooditem, :restaurant).where("orders.group IS NULL AND (disable_grouping_orders = false OR share_meeting_id IS NOT NULL)").order("restaurants.name, fooditems.name ASC, orders.id ASC")
      max = []
      grouping_rows, grouping_columns = runningmenu.address.grouping_rows, runningmenu.address.grouping_columns
      runningmenu.orders.active.pluck(:group).compact.each do |g|
        g.split(",").each do |a|
          max << a
        end
      end
      if max.blank? && !orders.blank?
        groups = Order.get_groups('A', grouping_rows, grouping_columns)
        counter = 0
        Order.fill_groups(groups, counter, orders, grouping_columns)
      else
        max_group = max.sort.last.split("-")
        group = max_group.first
        subgroup = group.last
        group_count = max_group.last.to_i
        if group_count == grouping_columns && subgroup == "#{grouping_rows}"
          counter = 0
          group = group.first.next
          groups = Order.get_groups(group, grouping_rows, grouping_columns)
        else
          counter = group_count
          alpha_group = group.first
          subgroups = (subgroup.to_i..grouping_rows).to_a
          groups = []
          subgroups.each do |n|
            groups += Array.new(grouping_columns, alpha_group+n.to_s)
          end
          # groups = groups.drop(counter)
          groups += Order.get_groups(alpha_group.next, grouping_rows, grouping_columns)
        end
        Order.fill_groups(groups, counter, orders, grouping_columns)
      end
    end
  end

  def self.groups_subgroups(order_group)
    # alphabets = []
    # order_group&.split(",")&.map{|a| alphabets.fill(a.split("-")[0], alphabets.size, a.split("-")[1].to_i) }
    # return alphabets&.map{|m| m.split("-")[0].scan(/\d+|[A-Za-z]+/)}.map{|x| x[0]+"-"+x[1]} rescue nil
    alphabets = order_group&.split(",")&.map{|a| a.split("-").first.first+"-"+a.split("-").first.last }
    return alphabets || []
  end

  def self.getrestaurant(scheduler, show_order_diff=false)
      if scheduler.present?
      self.find_by_sql("SELECT * FROM get_restaurant(#{scheduler.id}, #{show_order_diff})")
      end
  end

  def self.order_summary(scheduler, group_orders = true, restaurant_id = 0, address_id = 0, restaurant_address_id = 0)
    Order.find_by_sql("SELECT * FROM sp_order_summary(#{scheduler.id}, #{address_id}, #{restaurant_id}, #{restaurant_address_id}, #{group_orders})")
  end

  def self.order_summary_user(scheduler, show_order_diff, restaurant_id = 0, address_id = 0, restaurant_address_id = 0, summary_check = 0, from = '', to = '')
    if scheduler.orders.present?
      p_params = "#{scheduler.id}, #{address_id}, #{show_order_diff}, #{restaurant_id}, #{restaurant_address_id}, #{summary_check}, #{Runningmenu.menu_types[scheduler.menu_type]}, true"
      if from.present? && to.present?
        p_params += ", '#{from}', '#{to}'"
      end
      Order.find_by_sql("SELECT * FROM get_summary_detail(#{p_params})")
    end
  end

  def self.order_summary_pdf(changed_orders, all_before_cutoff_orders)
    total_orders = changed_orders + all_before_cutoff_orders
    billing_orders = total_orders.select{|s| s if s.order_status != 'cancelled'}.uniq
    before_cutoff_orders = billing_orders.reject{ |bo| changed_orders.pluck(:order_ids).include? bo.order_ids }
    before_cutoff_orders = before_cutoff_orders.uniq(&:order_ids)
    billing_orders = billing_orders.uniq(&:order_ids)
    [billing_orders, before_cutoff_orders]
  end

  def as_json(options = nil)
    super({ only: [:id, :price, :quantity, :total_price, :remarks], methods: [:orderrating, :rating_count, :average_rating, :ordered_at, :user_paid]  }.merge(options || {}))
  end

  def ordered_at
    self.runningmenu.delivery_at_timezone
  end

  def created_at_timezone
    self.created_at.in_time_zone(self.runningmenu.company.time_zone)
  end

  def orderrating
    self.rating.present?
  end

  def rating_count
    self.fooditem.rating_count
  end

  def average_rating
    self.fooditem.average_rating
  end

  def model_user_name
    self.share_meeting_id.present? ? "#{self.share_meeting.first_name} #{self.share_meeting.last_name}" : (self.guest_id.present? ? "#{self.guest.first_name} #{self.guest.last_name}" : "#{self.user.first_name} #{self.user.last_name}")
  end

  def model_email
    self.share_meeting_id.present? ? "#{self.share_meeting.email}" : (self.guest_id.present? ? "#{self.guest.email}" : "#{self.user.email}")
  end

  private

  def validate_fooditems
    if self.runningmenu.runningmenu_type != self.fooditem.menu.menu_type && !(self.runningmenu.addresses.include? self.fooditem.menu.address)
      errors[:base] << "Scheduled restaurants does not include this food item."
    end
  end

  def delivery_date_cannot_be_from_the_future
    if self.runningmenu.delivery_at < Time.current
      errors[:base] << "Order can't be updated if delivery date has been passed away."
    end
  end

  def initialize_attributes
    self.restaurant_address_id = self.fooditem.menu.address.id
    self.restaurant_id = self.fooditem.menu.address.addressable_id
  end

  def calculate_order_totalprice
    if self.runningmenu.buffet?
      self.company_price = self.fooditem.dishsize_fooditems.where(:dishsize_id=>self.dishsize_id).last.price + ((self.fooditem.skip_markup || self.runningmenu.company.enable_saas) ? 0 : (self.fooditem.dishsize_fooditems.where(:dishsize_id=>self.dishsize_id).last.price * self.runningmenu.company.buffet_addons_markup / 100))
    else
      self.company_price = self.fooditem.price
    end
    options_price = 0
    self.optionsets_orders.each do |optionset|
      optionset.options_orders.each do |options_order|
        self.company_price += options_order.option.price unless options_order.marked_for_destruction?
        options_price += options_order.option.price unless options_order.marked_for_destruction?
      end
    end
    self.food_price = self.runningmenu.buffet? ? (self.fooditem.dishsize_fooditems.where(:dishsize_id=>self.dishsize_id).last.price) + options_price : self.company_price
    company = self.runningmenu.company
    # 10
    # 11
    # 20
    if !self.runningmenu.buffet? && !self.user.unsubsidized_user?
      if self.fooditem.skip_markup? || company.enable_saas
        self.site_price = 0 # 4
      else
        self.site_price = company.markup # 4
      end
      # if !self.fooditem.skip_markup?
        if self.runningmenu.per_user_copay? && (((self.user.company_user? || self.user.company_manager?) && self.runningmenu.user_remaining_budget(self.user_id, nil, self.id) <=0) || (self.share_meeting.present? && self.runningmenu.user_remaining_budget(nil, self.share_meeting_id, self.id) <= 0))
          self.user_price = self.company_price
          self.company_price = 0
          self.user_markup = true
        elsif self.runningmenu.per_user_copay? && self.runningmenu.per_user_copay_amount? && (self.user.company_user? || self.user.company_manager? || self.share_meeting.present?) #5
          # 10 > 14
          # 11 > 14
          # 20 > 14
          remaining_budget = self.share_meeting.present? ? self.runningmenu.user_remaining_budget(nil, self.share_meeting_id, self.id) : self.runningmenu.user_remaining_budget(self.user_id, nil, self.id)
          if !self.fooditem.skip_markup? && !company.enable_saas && (remaining_budget - self.runningmenu.per_user_copay_amount < company.markup)
            company_paid = (remaining_budget - self.runningmenu.per_user_copay_amount) < 0 || (self.company_price + self.site_price) == self.runningmenu.per_user_copay_amount ? 0 : (remaining_budget - self.runningmenu.per_user_copay_amount)
            self.user_price = self.company_price - company_paid
            self.company_price = company_paid
            self.user_markup = true
          elsif self.fooditem.skip_markup? && company.enable_saas && remaining_budget < self.runningmenu.per_user_copay_amount
            self.user_price = self.company_price
          elsif self.company_price + self.site_price - self.runningmenu.per_user_copay_amount >= (remaining_budget - self.runningmenu.per_user_copay_amount)
            self.user_price = (self.company_price + self.site_price + self.runningmenu.per_user_copay_amount) - remaining_budget
            # 10 = 20 + 4 - 14
          else
            self.user_price = self.runningmenu.per_user_copay_amount
            # 5
            # 5
          end
          unless self.user_markup
            self.company_price = self.company_price - self.user_price
          end
          # 5+4 = 10 - 5
          # 6+4 = 11 - 5
          # 10+4 = 20 - 10
        elsif self.runningmenu.per_user_copay? && ((self.user.company_user? || self.user.company_manager?) || self.share_meeting.present?) && (self.company_price + self.site_price) > (self.share_meeting.present? ? self.runningmenu.user_remaining_budget(nil, self.share_meeting_id, self.id) : self.runningmenu.user_remaining_budget(self.user_id, nil, self.id))
          remaining_budget = self.share_meeting.present? ? self.runningmenu.user_remaining_budget(nil, self.share_meeting_id, self.id) : self.runningmenu.user_remaining_budget(self.user_id, nil, self.id)
          company_price = remaining_budget - self.site_price
          if company_price < 0
            self.user_price = self.company_price - remaining_budget
            self.company_price = remaining_budget
            self.user_markup = true
          else
            self.user_price = self.company_price + self.site_price - remaining_budget
            self.company_price = company_price
          end
        else
          self.user_price = 0
          self.user_markup = false
        end
        remaining_budget = self.share_meeting.present? ? self.runningmenu.user_remaining_budget(nil, self.share_meeting_id, self.id) : (self.user.company_user? || self.user.company_manager?) ? self.runningmenu.user_remaining_budget(self.user_id, nil, self.id) : self.runningmenu.per_meal_budget
        if !self.runningmenu.per_user_copay? && !self.fooditem.skip_markup? && !company.enable_saas && company.reduced_markup_check && (self.company_price + self.site_price) > remaining_budget# && (self.user.company_user? || self.share_meeting.present?)
          calculated_markup = company.markup - company.markup * company.reduced_markup / 100
          if self.company_price >= (remaining_budget - company.markup) &&
            self.company_price <= (remaining_budget - calculated_markup)

            self.site_price = remaining_budget - self.company_price
          end
        end
      # else
        # self.user_price = 0
      # end
    elsif self.user.unsubsidized_user?
      self.site_price = self.fooditem.skip_markup ? 0 : company.markup
      self.user_price = self.company_price
      self.company_price = 0
      self.user_markup = true
    else
      self.company_price = self.company_price
      self.user_price = 0
      self.site_price = 0
    end
    self.price = self.company_price + self.site_price + self.user_price
    self.user_paid = self.user_payable_amount
    self.company_paid = self.company_payable_amount
    if self.quantity.present?
      self.total_price = self.price * self.quantity
      self.food_price_total = self.food_price * self.quantity
    else
      self.total_price = self.price
      self.food_price_total = self.food_price
    end
  end

  def set_rating
    self.fooditem.rating_total += self.rating
    self.fooditem.rating_count += 1
    self.fooditem.average_rating = self.fooditem.rating_total / self.fooditem.rating_count
    self.fooditem.save!
  end

  # def self.orderprocessing
  #   puts "Order Processing Start"
  #   begin
  #     users = User.active.joins(:company).where("pending_total >= ? AND TO_CHAR(now() AT TIME ZONE companies.time_zone, 'HHam') = ?", Setting.min_amount, '03pm').where.not(customer_id: nil)
  #     puts "Order Processing: Users count #{users.count}"
  #     users.each do |user|
  #       if user.attempts_count < 3
  #         puts "Order Processing: In a loop user id #{user.id}"
  #         result = $gateway.transaction.sale(
  #           :customer_id => user.customer_id,
  #           :amount => user.pending_total,
  #           :options => {
  #             :submit_for_settlement => true
  #           }
  #         )
  #         orders = user.orders.active.pending.where("process = #{Order.processes['yes']} AND user_price > ?", 0).joins(runningmenu: [:company]).where("runningmenus.status = #{Runningmenu.statuses['approved']} AND runningmenus.delivery_at < ? AND TO_CHAR(now() AT TIME ZONE companies.time_zone, 'HHam') = ?", Time.current, '03pm').where(share_meeting_id: nil)
  #         if result.success?
  #           puts "Order Processing: Transaction successfully processed"
  #           Order.generate_logs(user, true, orders, "Transaction successfully processed", result.transaction.id, user.pending_total, '')
  #           user.pending_total = 0
  #           unless user.save!
  #             puts "Order Processing: User setting pending total 0 update failed"
  #           end
  #           orders.update_all(payment_status: :paid)
  #         else
  #           puts "Order Processing: transaction failed"
  #           message = result.message
  #           transaction_id = ''
  #           if result.transaction
  #             message = result.transaction.processor_response_text
  #             transaction_id = result.transaction.id
  #           end
  #           user.update(attempts_count: user.attempts_count + 1, valid_card: false)
  #           Order.generate_logs(user, false, orders, message, transaction_id, user.pending_total, '')
  #         end
  #       end
  #     end
  #   rescue StandardError => e
  #     puts "Order Processing: #{e}"
  #   end
  #   # begin
  #   #   meetings = ShareMeeting.pending.joins(:user, :runningmenu).where.not(customer_id: nil).where("runningmenus.status = #{Runningmenu.statuses['approved']} AND runningmenus.delivery_at < ? AND share_meetings.user_price > 0", Time.current)
  #   #   puts "Order Processing for meetings count: #{meetings.count}"
  #   #   meetings.each do |meeting|
  #   #     if meeting.attempts_count < 3
  #   #       puts "Order Processing: In a loop share meeting id #{meeting.id}"
  #   #       result = $gateway.transaction.sale(
  #   #         :customer_id => meeting.customer_id,
  #   #         :amount => meeting.user_price,
  #   #         :options => {
  #   #           :submit_for_settlement => true
  #   #         }
  #   #       )
  #   #       orders = meeting.orders.active.pending.where("user_price > ?", 0).joins(:runningmenu).where("runningmenus.status = #{Runningmenu.statuses['approved']} AND runningmenus.delivery_at < ?", Time.current).where.not(share_meeting_id: nil)
  #   #       if result.success?
  #   #         puts "Order Processing: Transaction successfully processed"
  #   #         Order.generate_logs(nil, true, orders, "Transaction successfully processed", result.transaction.id, meeting.user_price, meeting)
  #   #         meeting.user_price = 0
  #   #         unless meeting.save!
  #   #           puts "Order Processing share_meeting: ShareMeeting setting user price 0 update failed"
  #   #         end
  #   #         orders.update_all(payment_status: :paid)
  #   #         meeting.paid!
  #   #       else
  #   #         puts "Order Processing share_meeting: transaction failed"
  #   #         message = result.message
  #   #         transaction_id = ''
  #   #         if result.transaction
  #   #           message = result.transaction.processor_response_text
  #   #           transaction_id = result.transaction.id
  #   #         end
  #   #         meeting.update(attempts_count: meeting.attempts_count + 1, valid_card: false)
  #   #         Order.generate_logs(nil, false, orders, message, transaction_id, meeting.user_price, meeting)
  #   #       end
  #   #     end
  #   #   end
  #   # rescue StandardError => e
  #   #   puts "Order Processing share_meeting: #{e}"
  #   # end
  #   puts "Order Processing End"
  # end

  def self.survey(runningmenu)
    puts "Survey Start"
    begin
      orders = runningmenu.orders.active.joins(:restaurant).where("restaurants.name != ?", ENV['BEV_AND_MORE']).order(user_id: :asc, restaurant_id: :asc)
      runningmenu_id, user_id = nil, nil
      orders.each do |order|
        puts "Survey: In a loop order id #{order.id}"
        user = order.user
        if user.survey_mail? && runningmenu.address_id == user.address_id
          puts 'Survey: Sending email for feedback'
          email = OrderMailer.survey_alert(order, runningmenu)
          EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        end
        if user.company_admin? && user.survey_mail?
          if runningmenu_id != order.runningmenu_id || user_id != order.user_id
            puts 'Survey: Sending email for feedback'
            email = OrderMailer.admin_survey_alert(order, runningmenu)
            EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
          end
        end
        runningmenu_id, user_id = order.runningmenu_id, order.user_id
      end
    rescue StandardError => e
      puts "Survey: #{e}"
    end
    puts "Survey End"
  end

  # def self.survey
  #   puts "Survey Start"
  #   begin
  #     runningmenus = Runningmenu.approved.where('menu_type != ? AND hide_meeting = ?', Runningmenu.menu_types[:buffet], false).where(delivery_at: Time.current - 1.hour - 5.minutes..Time.current - 1.hour + 5.minutes)
  #     puts "Survey: runningmenu count #{runningmenus.count}"
  #     runningmenus.each do |runningmenu|
  #       puts "Survey: In a loop runningmenu id #{runningmenu.id}"
  #       orders = runningmenu.orders.active.where(restaurant_id: Restaurant.where.not(name: ENV['BEV_AND_MORE']).pluck(:id)).order(user_id: :asc, restaurant_id: :asc)
  #       puts "Survey: orders count #{orders.count}"
  #       if orders.present?
  #         restaurant_id, user_id = nil, nil
  #         orders.each do |order|
  #           puts "Survey: In a loop order id #{order.id}"
  #           if order.user.company_user? && order.user.survey_mail? && runningmenu.address_id == order.user.address_id
  #             puts 'Survey: Sending email for feedback'
  #             email = OrderMailer.survey_alert(order, runningmenu)
  #             EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #           elsif order.user.company_admin? && order.user.survey_mail?
  #             if restaurant_id != order.restaurant_id || user_id != order.user_id
  #               puts 'Survey: Sending email for feedback'
  #               email = OrderMailer.admin_survey_alert(order, runningmenu)
  #               EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #             end
  #           end
  #           restaurant_id, user_id = order.restaurant_id, order.user_id
  #         end
  #       end
  #       # puts "Survey: In a loop runningmenu id #{runningmenu.id}"
  #       # users = CompanyUser.active.where(id: Order.active.where(runningmenu_id: runningmenu).pluck('user_id').uniq)
  #       # puts "Survey: users count #{users.count}"
  #       # users.each do |user|
  #       #   puts "Survey: In a loop user id #{user.id}"
  #       #   if user.survey_mail?
  #       #     puts 'Survey: Sending email for feedback'
  #       #     email = OrderMailer.survey_alert(user, runningmenu)
  #       #     EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #       #   end
  #       # end
  #     end
  #   rescue StandardError => e
  #     puts "Survey: #{e}"
  #   end
  #   puts "Survey End"
  # end

  # def self.cutoff_reminder
  #   puts "Cutoff Reminder Start"
  #   begin
  #     runningmenus = Runningmenu.approved.where('menu_type != ? AND hide_meeting = ?', Runningmenu.menu_types[:buffet], false).where(cutoff_at: Time.current + 24.hour - 5.minutes..Time.current + 24.hour + 5.minutes)
  #     puts "Cutoff Reminder: Runningmenu count #{runningmenus.count}"
  #     runningmenus.each do |runningmenu|
  #       puts "Cutoff Reminder: In a loop runningmenu id #{runningmenu.id}"
  #       users = CompanyUser.active.where(company_id: runningmenu.company_id).where.not(id: Order.active.where(runningmenu_id: runningmenu.id).pluck('user_id').uniq)
  #       puts "Cutoff Reminder: Users count #{users.count}"
  #       users.each do |user|
  #         puts "Cutoff Reminder: In a loop user id #{user.id}"
  #         if user.send("cutoff_day_#{runningmenu.runningmenu_type}_reminder") && runningmenu.address_id == user.address_id
  #           puts 'Cutoff Reminder: Sending email for cut off cutoff_reminder'
  #           email = OrderMailer.no_order_placed(user, runningmenu)
  #           EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #         end
  #       end
  #     end

  #     runningmenus = Runningmenu.approved.where('menu_type != ? AND hide_meeting = ?', Runningmenu.menu_types[:buffet], false).where(cutoff_at: Time.current + 1.hour - 5.minutes..Time.current + 1.hour + 5.minutes)
  #     puts "Cutoff Reminder: Runningmenu count #{runningmenus.count}"
  #     runningmenus.each do |runningmenu|
  #       puts "Cutoff Reminder: In a loop runningmenu id #{runningmenu.id}"
  #       users = CompanyUser.active.where(company_id: runningmenu.company_id).where.not(id: Order.active.where(runningmenu_id: runningmenu.id).pluck('user_id').uniq)
  #       puts "Cutoff Reminder: Users count #{users.count}"
  #       users.each do |user|
  #         puts "Cutoff Reminder: In a loop user id #{user.id}"
  #         if user.send("cutoff_hour_#{runningmenu.runningmenu_type}_reminder") && runningmenu.address_id == user.address_id
  #           puts 'Cutoff Reminder: Sending email for cut off cutoff_reminder'
  #           email = OrderMailer.no_order_placed_last_chance(user, runningmenu)
  #           EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #         end
  #       end
  #     end
  #   rescue StandardError => e
  #     puts "Cutoff Reminder: #{e}"
  #   end
  #   puts "Cutoff Reminder End"
  # end

  def self.missed_restaurant_billing
    puts "Billing Check Start"
    first_restaurantbilling_runningmenu_deliver_at = ENV["START_TIME_BILLING"].in_time_zone(Rails.application.config.time_zone)
    begin
      orders = Order.active.joins(:runningmenu).where("runningmenus.delivery_at BETWEEN ? AND ? AND runningmenus.status = ? AND runningmenus.delivery_type = ?", first_restaurantbilling_runningmenu_deliver_at, (Time.current - 1.day).end_of_day, Runningmenu.statuses[:approved], Runningmenu.delivery_types[:pickup]).where(restaurant_billing_id: nil).order(created_at: :desc)
      if orders.present?
        email = OrderMailer.missing_restaurant_billing(orders)
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      end
    rescue StandardError => e
     puts "Billing Check: #{e}"
    end
    puts "Billing Check End"
  end

  def self.generate_logs(user, payment_success, orders, message, transaction_id, pendingtotal, share_meeting)
    if payment_success
      payment_log = PaymentLog.create(user: user, amount: pendingtotal, refund_amount: pendingtotal, payment_gateway: PaymentLog.payment_gateways[:braintree], status: PaymentLog.statuses[:success], message: message, transaction_id: transaction_id, email: share_meeting.present? ? share_meeting.email : '')
      payment_log.orders << orders

      email = OrderMailer.card_charged( user.present? ? user.email : share_meeting.email, orders)
      EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
    else
      payment_log = PaymentLog.create(user: user, amount: pendingtotal, refund_amount: pendingtotal, payment_gateway: PaymentLog.payment_gateways[:braintree], status: PaymentLog.statuses[:failed], message: message, transaction_id: transaction_id, email: share_meeting.present? ? share_meeting.email : '')
      payment_log.orders << orders

      email = OrderMailer.card_charged_error(orders, message)
      EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      failed_email = OrderMailer.card_charge_failed( user.present? ? user.email : share_meeting.email, orders, message, user.present? ? user.attempts_count : share_meeting.attempts_count, share_meeting)
      EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: failed_email.subject, recipient: failed_email.to.first, body: Base64.encode64(failed_email.body.raw_source))
    end
  end

  def self.cloning_details(runningmenu, user)
    active_orders = runningmenu.orders.active.joins(:runningmenu).where("runningmenus.company_id = ?", user.company_id)
    total_quantity = (user.company_user? || user.company_manager?) ? active_orders.where(user_id: user.id).sum(:quantity).to_i : active_orders.sum(:quantity).to_i
    total_orders = active_orders.where.not(restaurant_address_id: Restaurant.find_by(name: ENV['BEV_AND_MORE']).addresses.active.first&.id)
    total_order_price = total_orders.sum(:total_price)
    total_order_quantity = total_orders.sum(:quantity).to_i
    [total_quantity, total_order_price/total_order_quantity,active_orders.sum(:total_price)]
  end

end
