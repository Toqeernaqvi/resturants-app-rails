class RestaurantBilling < ApplicationRecord

  # SALES_TAX_PERCENTAGE = 9.25

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  belongs_to :restaurant
  belongs_to :address
  # has_one :restaurant_admin, through: :address
  has_many :orders
  has_many :adjustments, as: :adjustable
  accepts_nested_attributes_for :adjustments, allow_destroy: true
  enum payment_status: [:generated, :paid, :final, :due]
  enum payment_method: [:credit_card, :check]
  enum status: [:active, :deleted]
  enum billing_type: [:individual, :buffet]
  before_create :set_billing_number

  validates :credit_card_fees, :tips, numericality: {greater_than_or_equal_to: 0}
  before_save :set_payout, if: lambda { |billing| billing.will_save_change_to_tips? || billing.will_save_change_to_credit_card_fees? }
  after_save :after_save_billing
  after_create_commit :set_final_status_job, if: lambda { |b| b.active? && b.generated? }
  
  # after_save :set_calculation_at_qb, if: lambda { |i| (i.saved_change_to_credit_card_fees? || i.saved_change_to_tips?) && !i.saved_change_to_id? && i.final? }
  # after_save :set_due_date_at_qb, if: lambda { |i| i.saved_change_to_due_date? && !i.saved_change_to_id? && i.final? }
  # after_save :set_paid_status_at_qb, if: lambda { |i| i.saved_change_to_payment_status? && i.paid? && !i.saved_change_to_id? }
  # after_save :upload_to_quickbook, if: lambda { |i| i.saved_change_to_payment_status? && i.final? && !i.saved_change_to_id? }
  # after_save :set_qb_status, if: lambda { |i| i.saved_change_to_status? && !i.saved_change_to_id? }

  def after_save_billing
    set_calculation_at_qb if (self.saved_change_to_credit_card_fees? || self.saved_change_to_tips?) && !self.saved_change_to_id? && self.final?
    set_due_date_at_qb if self.saved_change_to_due_date? && !self.saved_change_to_id? && self.final?
    set_paid_status_at_qb if self.saved_change_to_payment_status? && self.paid? && !self.saved_change_to_id?
    upload_to_quickbook if self.saved_change_to_payment_status? && self.final? && !self.saved_change_to_id?
    set_qb_status if self.saved_change_to_status? && !self.saved_change_to_id?
    set_due_status_job if self.active? && self.saved_change_to_payment_status? && self.final?
  end

  def set_final_status_job
    if self.final_status_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.final_status_job_id)
      job.delete unless job.nil?
    end
    time = Time.current.in_time_zone(self.restaurant.time_zone)
    if time.saturday?
      time = time+1.week
    else
      time = time.end_of_week-1.day
    end 
    job_id = SetFinalRestaurantBillingWorker.perform_at(time.change(hour: 0).utc, self.id)
    self.update_column(:final_status_job_id, job_id)
  end

  def set_due_status_job
    if self.due_status_job_id.present?
      job = Sidekiq::ScheduledSet.new.find_job(self.due_status_job_id)
      job.delete unless job.nil?
    end
    job_id = SetDueRestaurantBillingWorker.perform_at(self.due_date.in_time_zone(self.restaurant.time_zone).utc, self.id)
    self.update_column(:due_status_job_id, job_id)
  end

  def set_billing_number
    bill_num = RestaurantBilling.select('MAX(billing_number) AS billing_number').group('restaurant_billings.id').last.billing_number
    self.billing_number = bill_num.blank? ? 20000 : bill_num+1
  end

  # def due_at
  #   self.address.delayed_payout_days.days.since( self.orders.joins(:runningmenu).order("runningmenus.delivery_at desc").pluck("runningmenus.delivery_at").first )
  # end

  def orders_from_timezone
    self.orders_from&.in_time_zone(self.restaurant.time_zone)
  end

  def orders_to_timezone
    self.orders_to&.in_time_zone(self.restaurant.time_zone)
  end

  def discount_percentage
    self.food_total > 0 ? (self.commission/self.food_total * 100)&.round(2) : 0.0
  end

  # def orders_food_total(orders)
  #   (sprintf "%.2f", orders.sum(&:food_price_total)).to_f
  # end

  # def orders_commission(orders)
  #   if self.buffet?
  #     discount_percentage = (orders.sum(&:quantity) >= self.address.items_count || self.orders_food_total(orders) >= self.address.minimum_discount_price) ? (self.address.add_contract_commission ? (self.address.discount_percentage + self.address.buffet_commission) : self.address.buffet_commission) : 0
  #     (sprintf "%.2f", ((self.orders_food_total(orders) * discount_percentage)/100) ).to_f
  #   else
  #     (sprintf "%.2f", ((self.orders_food_total(orders) * self.address.discount_percentage)/100) ).to_f
  #   end
  # end

  def sale_tax_percentage
    (sprintf "%.4f",(TaxRate.exists?(zip: self.address.zip) ? TaxRate.find_by(zip: self.address.zip).estimated_combined_rate : 0.0925)).to_f
  end

  # def orders_sales_tax(orders)
  #   (sprintf "%.2f", (self.orders_food_total(orders) * self.sale_tax_percentage)).to_f
  #   # (sprintf "%.2f", ((self.orders_food_total(orders) * SALES_TAX_PERCENTAGE)/100)).to_f
  # end

  # def orders_from
  #   self.orders.active.joins(:runningmenu).where(runningmenus: {status: Runningmenu.statuses[:approved]}).order("runningmenus.delivery_at ASC").pluck(:delivery_at).first.in_time_zone(Rails.application.config.time_zone)
  # end
  #
  # def orders_to
  #   self.orders.active.joins(:runningmenu).where(runningmenus: {status: Runningmenu.statuses[:approved]}).order("runningmenus.delivery_at DESC").pluck(:delivery_at).first.in_time_zone(Rails.application.config.time_zone)
  # end

  def total_payout
    payout_total_ = self.food_total - self.commission + self.sales_tax - self.credit_card_fees + self.tips
    sprintf('%.2f', payout_total_)
  end

  def set_payout
    self.payout_total = self.food_total - self.commission + self.sales_tax - self.credit_card_fees + self.tips - self.adjustments.sum(&:price)
  end

  def calculate_total_dues
    sorted_deliveries = self.orders.active.joins(:runningmenu).where(runningmenus: {status: Runningmenu.statuses[:approved]}).order("runningmenus.delivery_at ASC").pluck(:delivery_at)
    orders_from_ = sorted_deliveries.first.in_time_zone(self.restaurant.time_zone)
    orders_to_ = sorted_deliveries.last.in_time_zone(self.restaurant.time_zone)
    record = Order.find_by_sql("SELECT SUM(food_price_total) AS food_total, SUM(restaurant_commission) AS commission_total, SUM(sales_tax) AS sales_tax_total, SUM(quantity) AS quantity FROM orders WHERE orders.restaurant_billing_id = #{self.id} AND orders.status = 0 LIMIT 1").first
    quantity_total_ = record.quantity
    food_total_ = record.food_total
    commission_ = record.commission_total&.round(2)
    sales_tax_ = record.sales_tax_total&.round(2)
    due_date_ = self.address.delayed_payout_days.days.since(orders_to_)
    total_payout_ = food_total_ - commission_ + sales_tax_ - self.credit_card_fees + self.tips - self.adjustments.sum(&:price)
    self.update_columns(orders_from: orders_from_, orders_to: orders_to_, quantity_total: quantity_total_, food_total: food_total_, commission: commission_, sales_tax: sales_tax_, due_date: due_date_, payout_total: total_payout_)
  end

  def set_final_status
    # if self.commission == 0
    #   self.update_columns(payment_status: RestaurantBilling.payment_statuses[:due])
    # else
      self.update(payment_status: RestaurantBilling.payment_statuses[:final])
    # end
  end

  def set_due_status
    self.update_column(:payment_status, RestaurantBilling.payment_statuses[:due])
  end

  # def self.set_final_status
  #   #Runs on each Saturday at 12AM
  #   puts "RestaurantBilling: set final status start"
  #   begin
  #     restaurants = Restaurant.joins(:restaurant_billings).where("restaurant_billings.status = ? AND restaurant_billings.payment_status = ?", RestaurantBilling.statuses[:active], RestaurantBilling.payment_statuses[:generated])
  #     restaurants.each do |restaurant|
  #       if Time.current.in_time_zone(restaurant.time_zone).strftime("%A, %I%P") == 'Saturday, 12am'
  #         billings = RestaurantBilling.active.generated.where(restaurant_id: restaurant.id)
  #         billings&.each do |rest_bill|
  #           # rest_bill.update_columns(payment_status: (rest_bill.commission == 0 ? RestaurantBilling.payment_statuses[:due] : RestaurantBilling.payment_statuses[:final]))
  #           if rest_bill.commission == 0
  #             rest_bill.update_columns(payment_status: RestaurantBilling.payment_statuses[:due])
  #           else
  #             rest_bill.update(payment_status: RestaurantBilling.payment_statuses[:final])
  #           end
  #         end
  #       end
  #     end
  #   rescue Exception => e
  #     puts "RestaurantBilling: Exception-#{e}"
  #   end
  # end

  # def self.set_status_to_due
  #   puts "RestaurantBilling: set status to due start"
  #   begin
  #     restaurants = Restaurant.joins(:restaurant_billings).where("restaurant_billings.status = ? AND restaurant_billings.payment_status = ? AND restaurant_billings.due_date <= ?", RestaurantBilling.statuses[:active], RestaurantBilling.payment_statuses[:final], Time.current.to_date)
  #     restaurants.each do |restaurant|
  #       if Time.current.in_time_zone(restaurant.time_zone).strftime("%I%P") == '12am'
  #         billings = RestaurantBilling.active.final.where("due_date <= ? AND restaurant_id = ?", Time.current.to_date, restaurant.id)
  #         billings&.each do |rest_bill|
  #           rest_bill.update_column(:payment_status, RestaurantBilling.payment_statuses[:due])
  #         end
  #       end
  #     end
  #   rescue Exception => e
  #     puts "RestaurantBilling: Exception-#{e}"
  #   end
  # end

  def self.generate(runningmenu)
    puts "Restaurant Payout Start for #{runningmenu.menu_type}"
    begin
      runningmenu.orders.active.where(restaurant_billing_id: nil).group_by{|o| [o.restaurant_id, o.restaurant_address_id] }.each do |group, orders|
        restaurant_billing = RestaurantBilling.active.generated.send("#{runningmenu.menu_type}").where(restaurant_id: group[0], address_id: group[1]).last
        if restaurant_billing.blank?
          restaurant_billing = RestaurantBilling.create(restaurant_id: group[0], address_id: group[1], billing_type: runningmenu.menu_type)
        end
        Order.where(id: orders.pluck(:id)).update_all(restaurant_billing_id: restaurant_billing.id)
        restaurant_billing.calculate_total_dues
      end
    rescue StandardError => e
      puts "Restaurant Payout Error for #{runningmenu.menu_type}: #{e}"
    end
    puts "Restaurant Payout End for #{runningmenu.menu_type}"
  end

  # def self.generate
  #   puts "Restaurant Payout Start for individual"
  #   begin
  #     orders_ = Order.active.joins(:runningmenu).where("runningmenus.delivery_at BETWEEN ? AND ? AND runningmenus.menu_type = ? AND runningmenus.delivery_type = ?", 5.minutes.ago.beginning_of_minute, 5.minutes.since.beginning_of_minute, Runningmenu.menu_types[:individual], Runningmenu.delivery_types[:pickup])
  #     orders_.group_by{|o| [o.restaurant_id, o.restaurant_address_id] }.each do |group, orders|
  #       restaurant_billing = RestaurantBilling.active.generated.individual.where(restaurant_id: group[0], address_id: group[1]).last
  #       if restaurant_billing.blank?
  #         restaurant_billing = RestaurantBilling.create(restaurant_id: group[0], address_id: group[1], billing_type: RestaurantBilling.billing_types[:individual])
  #       end
  #       Order.where(id: orders.pluck(:id)).update_all(restaurant_billing_id: restaurant_billing.id)
  #       restaurant_billing.calculate_total_dues
  #     end
  #   rescue StandardError => e
  #     puts "Restaurant Payout Error for individual: #{e}"
  #   end
  #   puts "Restaurant Payout End for individual"

  #   puts "Restaurant Payout Start for Buffet"
  #   begin
  #     orders_ = Order.active.joins(:runningmenu).where("runningmenus.delivery_at BETWEEN ? AND ? AND runningmenus.menu_type = ? AND runningmenus.delivery_type = ?", 5.minutes.ago.beginning_of_minute, 5.minutes.since.beginning_of_minute, Runningmenu.menu_types[:buffet], Runningmenu.delivery_types[:pickup])
  #     orders_.group_by{|o| [o.restaurant_id, o.restaurant_address_id] }.each do |group, orders|
  #       restaurant_billing = RestaurantBilling.active.generated.buffet.where(restaurant_id: group[0], address_id: group[1]).last
  #       if restaurant_billing.blank?
  #         restaurant_billing = RestaurantBilling.create(restaurant_id: group[0], address_id: group[1], billing_type: RestaurantBilling.billing_types[:buffet])
  #       end
  #       Order.where(id: orders.pluck(:id)).update_all(restaurant_billing_id: restaurant_billing.id)
  #       restaurant_billing.calculate_total_dues
  #     end
  #   rescue StandardError => e
  #     puts "Restaurant Payout Error for Buffet: #{e}"
  #   end
  #   puts "Restaurant Payout End for Buffet"
  # end

  # def self.pay_to_restaurants
  #   puts "RestaurantBilling: Start"
  #   begin
  #     billings = RestaurantBilling.active.generated.includes(:restaurant_admin).where(due_date: Time.current.to_date)
  #     unless billings.blank?
  #       billings.each do |billing|
  #         if billing.restaurant_admin.blank?
  #           puts "RestaurantBilling: #{billing.address.name} does not have any admin"
  #         elsif billing.restaurant_admin.stripe_user_id.blank?
  #           puts "RestaurantBilling: #{billing.restaurant_admin.name} not connected to chowmill stripe account."
  #         else
  #           puts "RestaurantBilling: payment start"
  #           charge = Stripe::Charge.create({
  #             amount: billing.commission(billing.orders.active)*100,
  #             currency: "usd",
  #             source: "tok_visa",
  #             transfer_data: {
  #               destination: "#{billing.restaurant_admin.stripe_user_id}",
  #             },
  #           })
  #           puts "RestaurantBilling: Charge status- #{charge.status}"
  #           if charge.status == "succeeded"
  #             billing.paid!
  #             OrderMailer.paid_orders(billing.restaurant_admin, billing.orders.active).deliver_later
  #           end
  #         end
  #       end
  #     end
  #   rescue Exception => e
  #     puts "RestaurantBilling: Exception-#{e}"
  #   end
  # end

  def quickbooks_due_days_terms(term_days, setting, access_token)
    term_name = term_days.to_s+" days"
    begin
      service = Quickbooks::Service::Term.new
      service.company_id = setting.realmid
      service.access_token = access_token
      term = service.find_by(:name, term_name)
      if term.first.present?
        return term.first.id
      else
        term = Quickbooks::Model::Term.new
        term.name = term_name
        term.due_days = term_days
        created_term = service.create(term)
        puts "###################################################### Billing Term id is: "+created_term.id.to_s
        return created_term.id
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
      self.inform_finance(e.message)
    end
  end

  def set_line_items(qb_billing, item, new_record)
    billing = self
    rm_ids = billing.orders.pluck(:runningmenu_id).uniq
    meetings_count = rm_ids.length
    adjustment = billing.adjustments.sum(&:price)/meetings_count
    credit_card_fee = billing.credit_card_fees/meetings_count
    tip = billing.tips/meetings_count
    restaurant_address_id = billing.address_id
    Runningmenu.where(:id=>rm_ids).each do |meeting|
      orders = meeting.orders.active.where(:restaurant_address_id=>restaurant_address_id)
      quantity = orders.sum(:quantity)
      food_total = orders.sum(:food_price_total)
      commission = orders.sum(:restaurant_commission)&.round(2)
      sales_tax = orders.sum(&:sales_tax)&.round(2)
      if new_record
        line_item = Quickbooks::Model::BillLineItem.new
        line_item.amount = billing.meeting_total_payout(food_total, commission, sales_tax, credit_card_fee, tip, adjustment)
        line_item.description = "Meeting Date #{meeting.delivery_at.strftime("%m/%d/%Y")} and total items: #{quantity.to_i}"
        line_item.account_based_expense_item! do |detail|
          detail.account_id = item.first.income_account_ref.value
        end
        qb_billing.line_items << line_item
      else
        description = "Meeting Date #{meeting.delivery_at.strftime("%m/%d/%Y")} and total items: #{quantity.to_i}"
        line_item = qb_billing.line_items.select{|li| li if li.description == description}.last
        line_item.amount = billing.meeting_total_payout(food_total, commission, sales_tax, credit_card_fee, tip, adjustment) unless line_item.nil?
      end
    end
    qb_billing
  end

  def meeting_total_payout(food_total, commission, sales_tax, credit_card_fee, tip, adjustment)
    payout_total = food_total - commission + sales_tax - credit_card_fee + tip - adjustment
    sprintf('%.2f', payout_total)
  end

  def upload_to_quickbook
    billing = self
    setting = Setting.latest
    access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
    term_days = billing.address.delayed_payout_days.to_i
    service = Quickbooks::Service::Item.new
    service.company_id = setting.realmid
    service.access_token = access_token
    item = service.find_by(:sku, ENV["QB_BILL_ITEM_SKU"])
    if item.first.present?
      begin
        qb_billing = Quickbooks::Model::Bill.new
        qb_billing.vendor_id = billing.restaurant.quickbooks_identity(setting, access_token)
        qb_billing.doc_number = billing.billing_number
        qb_billing.due_date = billing.due_date.strftime("%Y-%m-%d")
        qb_billing.total = billing.payout_total.to_s
        qb_billing.currency_ref = Quickbooks::Model::BaseReference.new('USD')
        if term_days > 0
          terms = billing.quickbooks_due_days_terms(term_days, setting, access_token)
          qb_billing.sales_term_ref = Quickbooks::Model::BaseReference.new(terms)
        end
        qb_billing = billing.set_line_items(qb_billing, item, true)
        service = Quickbooks::Service::Bill.new
        service.company_id = setting.realmid
        service.access_token = access_token
        created_billing = service.create(qb_billing)
        QuickbookLog.create!(upload_identity: billing.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[1]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[0]], quickbook_identity: created_billing.id)
        puts "###################################################### Created Billing id is: "+created_billing.id.to_s
      rescue StandardError => e
        puts "###################################################### Quickbook error: #{e.message}"
        self.inform_finance(e.message)
      end
    end
  end

  def set_calculation_at_qb
    begin
      setting = Setting.latest
      access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
      service = Quickbooks::Service::Bill.new
      service.company_id = setting.realmid
      service.access_token = access_token
      result = service.find_by(:doc_number, self.billing_number)
      if result.first.present?
        qb_billing = result.first
        qb_billing.total = self.payout_total
        qb_billing = self.set_line_items(qb_billing, nil, false)
        upated_billing = service.update(qb_billing, :sparse => true)
        QuickbookLog.create!(upload_identity: self.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[1]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[1]], quickbook_identity: upated_billing.id)
        puts "###################################################### Updated calculation and Billing id is: "+upated_billing.id.to_s
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
      self.inform_finance(e.message)
    end
  end

  def set_adjustment_calculation_at_qb(price)
    begin
      setting = Setting.latest
      access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
      service = Quickbooks::Service::Bill.new
      service.company_id = setting.realmid
      service.access_token = access_token
      result = service.find_by(:doc_number, self.billing_number)
      if result.first.present?
        qb_billing = result.first
        qb_billing.total = (self.total_payout.to_f - price).to_s
        qb_billing = self.set_line_items(qb_billing, nil, false)
        upated_billing = service.update(qb_billing, :sparse => true)
        QuickbookLog.create!(upload_identity: self.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[1]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[1]], quickbook_identity: upated_billing.id)
        puts "###################################################### Updated calculation and Billing id is: "+upated_billing.id.to_s
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
      self.inform_finance(e.message)
    end
  end

  def set_due_date_at_qb
    begin
      setting = Setting.latest
      access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
      service = Quickbooks::Service::Bill.new
      service.company_id = setting.realmid
      service.access_token = access_token
      result = service.find_by(:doc_number, self.billing_number)
      if result.first.present?
        qb_billing = result.first
        qb_billing.due_date = self.due_date.strftime("%Y-%m-%d")
        upated_billing = service.update(qb_billing, :sparse => true)
        QuickbookLog.create!(upload_identity: self.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[1]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[1]], quickbook_identity: upated_billing.id)
        puts "###################################################### Updated due date and Billing id is: "+upated_billing.id.to_s
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
      self.inform_finance(e.message)
    end
  end

  def set_paid_status_at_qb
    begin
      setting = Setting.latest
      access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
      service = Quickbooks::Service::Bill.new
      service.company_id = setting.realmid
      service.access_token = access_token
      result = service.find_by(:doc_number, self.billing_number)
      if result.first.present?
        qb_billing = result.first
        # qb_billing.balance = 0.0
        # qb_billing.total = 0.0
        # qb_billing.line_items.each do |li|
        #   li.amount = 0.0
        # end
        upated_billing = service.update(qb_billing, :sparse => true)
        QuickbookLog.create!(upload_identity: self.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[1]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[1]], quickbook_identity: upated_billing.id)
        puts "###################################################### Updated paid and Billing id is: "+upated_billing.id.to_s
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
      self.inform_finance(e.message)
    end
  end

  def set_qb_status
    setting = Setting.latest
    access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
    if self.active?
      self.upload_to_quickbook
    else
      self.remove_from_quickbooks(self.id, setting, access_token)
    end
  end

  def remove_from_quickbooks(billing_id, setting, access_token)
     begin
      service = Quickbooks::Service::Bill.new
      service.company_id = setting.realmid
      service.access_token = access_token
      result = service.find_by(:doc_number, self.billing_number)
      if result.first.present?
        bill = result.first
        deleted_bill = service.delete(bill)
        if deleted_bill
          QuickbookLog.create!(upload_identity: self.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[1]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[2]], quickbook_identity: bill.id)
          puts "###################################################### Deleted Billing id is: "+bill.id
        end
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
      self.inform_finance(e.message)
    end
  end

  def inform_finance(message)
    email = WebhookMailer.quickbook_error(message, self.id, "Billing")
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  end

  ransacker :all_preferred_partner, formatter: proc {|value|
    results = RestaurantBilling.joins(:restaurant => :addresses).where("addresses.discount_percentage > ?", 0.0).pluck(:id).uniq
    results = results.present? ? results.uniq : nil
  } do |parent|
    parent.table[:id]
  end

end
