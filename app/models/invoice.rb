class Invoice < ApplicationRecord
  enum status: [:generated, :sent, :paid, :deposited]
  enum delivery_type: [:pickup, :delivery]

  belongs_to :company, :inverse_of => :invoices
  belongs_to :restaurant, optional: true
  belongs_to :restaurant_address, optional: true
  before_validation :set_dates_in_company_timezone, if: lambda { |r| r.skip_set_dates.blank? }

  before_create :set_invoice_number
  has_many :orders
  has_many :adjustments, as: :adjustable
  has_many :line_items, dependent: :destroy

  attr_accessor :deliveries, :skip_set_dates, :skip_validate_status

  accepts_nested_attributes_for :line_items
  accepts_nested_attributes_for :adjustments, allow_destroy: true
  after_create :add_default_lineitem
  # validate :satus_cannot_changed, if: lambda{|i| i.will_save_change_to_status? && i.charged_cc && !i.skip_validate_status }

  after_save :set_dates_at_qb, if: lambda { |i| (i.saved_change_to_ship_date? || i.saved_change_to_from? || i.saved_change_to_due_date?) && !i.saved_change_to_id? }
  after_save :set_qb_status, if: lambda { |i| i.saved_change_to_status? && i.paid? && !i.saved_change_to_id? }

  before_destroy :remove_from_quickbooks

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  ransacker :company, formatter: proc {|value|
    results = Invoice.joins(:orders => :runningmenu).where('runningmenus.company_id = ?', value.to_i).uniq.pluck(:id)
    results = results.present? ? results : nil
   } do |parent|
    parent.table[:id]
  end

  def time_zone
    self.company.time_zone rescue Rails.application.config.time_zone
  end

  def satus_cannot_changed
      errors.add(:status, "Status can't be changed after card is charged")
  end

  def paid_date_timezone
    self.paid_date&.in_time_zone(self.time_zone)
  end

  def created_at_timezone
    self.created_at.in_time_zone(self.time_zone)
  end

  def due_date_timezone
    self.due_date.in_time_zone(self.time_zone)
  end

  def ship_date_timezone
    self.ship_date.in_time_zone(self.time_zone)
  end

  def from_timezone
    self.from&.in_time_zone(self.time_zone)
  end

  def to_timezone
    self.to&.in_time_zone(self.time_zone)
  end

  def sale_tax_percentage
    (sprintf "%.4f",(TaxRate.exists?(zip: self.restaurant_address.zip) ? TaxRate.find_by(zip: self.restaurant_address.zip).estimated_combined_rate : 0.0925)).to_f
  end

  def shipping
    begin
    from.blank? ? ship_date_timezone.strftime("%m/%d/%Y") + " - " + ship_date_timezone.strftime("%m/%d/%Y") : from_timezone.strftime("%m/%d/%Y") + " - " + to_timezone.strftime("%m/%d/%Y")
    rescue
      nil
    end
  end

  def shipping_body
    from.blank? ? ship_date_timezone.strftime("%m/%d/%Y") + " - " + ship_date_timezone.strftime("%m/%d/%Y") : from_timezone.strftime("%m/%d/%Y") + " - " + to_timezone.strftime("%m/%d/%Y")
  end

  def shipping_subject
    from.blank? ? ship_date_timezone.strftime("%b. %d") : from_timezone.strftime("%b. %d") + " - " + to_timezone.strftime("%b. %d")
  end

  def set_dates_in_company_timezone
    if self.from.present?
      from_n = self.from_timezone.formatted_offset.to_f
      self.from = (self.from - from_n.hours)
    end

    if self.to.present?
      to_n = self.to_timezone.formatted_offset.to_f
      self.to = (self.to - to_n.hours)
    end
    due_date_n = self.due_date_timezone.formatted_offset.to_f
    shipt_date_n = self.ship_date_timezone.formatted_offset.to_f
    self.due_date = (self.due_date - due_date_n.hours)
    self.ship_date = (self.ship_date - shipt_date_n.hours)
  end

  def approvers
    self.orders.first.runningmenu.company.billing.approvers
  end

  def invoice_email
    self.orders.last.runningmenu.runningmenufields.joins(:field).find_by("fields.name = ?", "Invoice Email")&.fieldoption&.name
  end

  def add_default_lineitem
    # self.line_items.create(quantity: 1, item: "Delivery Fee", unit_price: 29.99, amount: 29.99)
    self.line_items.create(quantity: self.deliveries, item: "Delivery & Service Fee", unit_price: self.delivery_fee, amount: self.delivery_fee*self.deliveries, default_line_item: "yes")
  end

  def set_invoice_number
    inv_num = Invoice.select('MAX(invoice_number) AS invoice_number').group(:id).last.invoice_number
    self.invoice_number = inv_num.blank? ? 10001 : inv_num+1
  end

  def calculate_total_dues
    price_sum = self.orders.active.sum{|a| (a.total_price - a.user_paid)} + self.line_items.sum(:amount) + self.adjustments.where(adjustment_type: Adjustment.adjustment_types[:addition]).sum(:price)
    discount_sum = self.line_items.sum(:discount) + self.adjustments.where(adjustment_type: Adjustment.adjustment_types[:discount]).sum(:price)
    due_amount_total = price_sum - discount_sum
    _sales_tax = self.company.billing&.separate_out_sales_tax_on_invoices ? self.orders.active.sum(:sales_tax) : 0
    self.update_columns(delivery_fee_total: self.line_items.where("item ILIKE '%delivery%'").sum(:amount), total_amount: price_sum, total_discount: discount_sum, total_amount_due: due_amount_total, sales_tax: _sales_tax)
  end

  def amount_due_without_fee
    self.total_amount_due - self.line_items.where("item ILIKE '%delivery%'").sum(:amount)
  end

  def inform_finance(message)
    email = WebhookMailer.quickbook_error(message, self.id, "Invoice")
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  end

  def self.generate(options=nil)
    puts "Invoice generate start"
    begin
      invoice_ids = []
      if options.present? && options[:runningmenu_id].present?
        orders = Order.active.joins(:runningmenu).select("orders.*, runningmenus.company_id, runningmenus.address_id, orders.id AS order_id, (CASE WHEN runningmenus.delivery_type = 1 THEN 'delivery' ELSE 'pickup' END) AS delivery_type").where(runningmenu_id: options[:runningmenu_id], invoice_id: nil)
        orders.group_by{|o| [o.company_id]}.each do |key, orders_hash|
          invoice = Invoice.init_invoice_attributes(key, orders_hash, nil, nil)
          invoice_ids << invoice.id
        end
      else
        back_time, current_time = Time.current.ago(59.minutes), Time.current
        back_time, current_time = back_time.beginning_of_minute.utc.to_s(:db), current_time.beginning_of_minute.utc.to_s(:db)
        orders = Order.find_by_sql("SELECT * FROM get_orders('#{back_time}',' #{current_time}')")
        orders.group_by{|o| [o.company_id, o.bm&.downcase, o.gl&.downcase, o.ie&.downcase]}.each do |key, orders_hash|
          invoice = Invoice.init_invoice_attributes(key, orders_hash, nil, nil)
          invoice_ids << invoice.id
        end
      end
      unless invoice_ids.blank?
        UploadToQuickbookJob.perform_later(invoice_ids)
      end
    rescue StandardError => e
      puts "Invoice Error: #{e}"
    end
    puts "Invoice generate end"
  end

  def self.generate_company_invoice(start_date, end_date, company_id)
    puts "Invoice Start"
    begin
      company = Company.find company_id
      from = start_date.in_time_zone(company.time_zone).beginning_of_day.utc.to_s(:db)
      to = end_date.in_time_zone(company.time_zone).end_of_day.utc.to_s(:db)
      invoice_from = start_date.in_time_zone(company.time_zone).beginning_of_day
      invoice_to = end_date.in_time_zone(company.time_zone).end_of_day
      invoice_ids = []
      orders = Order.find_by_sql("SELECT * FROM get_orders('#{from}',' #{to}', '#{company.id}')")
      delivery_orders = orders.select{|o| o if o.delivery_type=='delivery' }
      orders = orders - delivery_orders
      orders.group_by{|o| [o.company_id, o.bm&.downcase, o.gl&.downcase, o.ie&.downcase]}.each do |key, orders_hash|
        invoice = Invoice.init_invoice_attributes(key, orders_hash, invoice_from, invoice_to)
        invoice_ids << invoice.id
      end
      delivery_orders.group_by{|o| [o.company_id, o.bm&.downcase, o.gl&.downcase, o.ie&.downcase, o.restaurant_address_id]}.each do |key, orders_hash|
        invoice = Invoice.init_invoice_attributes(key, orders_hash, invoice_from, invoice_to)
        invoice_ids << invoice.id
      end
      unless invoice_ids.blank?
        UploadToQuickbookJob.perform_later(invoice_ids)
      end
      return [orders.count + delivery_orders.count,invoice_ids]
    rescue StandardError => e
      puts "Invoice: #{e}"
    end
    puts "Invoice End"
  end

  def self.init_invoice_attributes(key, orders_hash, invoice_from, invoice_to)
    delivery_type = orders_hash.first.delivery_type
    company = Company.find(key[0])
    ordered_at = orders_hash.first.ordered_at.in_time_zone(company.time_zone)
    ship_to = bill_to = ""
    delivery_fee = 0.0
    deliveries = Runningmenu.where(:id=>orders_hash.pluck(:runningmenu_id).uniq).collect{|c| c.delivery_at_timezone.strftime("%d/%m/%Y %H") }.uniq.length
    if delivery_type == 'delivery'
      company_address = CompanyAddress.find(orders_hash.first.address_id)
      restaurant_address = RestaurantAddress.find(orders_hash.first.restaurant_address_id)
      bill_to = "#{restaurant_address.addressable.name} <br />#{restaurant_address.address_line}"
      ship_to = "#{company.name} <br />#{company_address.formatted_address}"
      _current_time = Time.current.in_time_zone(company.time_zone)
      invoice = Invoice.create(skip_set_dates: true, company_id: company.id, bill_to: bill_to, ship_to: ship_to, ship_date: ordered_at, payment_terms: "Due Upon Receipt", due_date: _current_time, deliveries: deliveries, delivery_fee: restaurant_address.delivery_cost, restaurant_id: orders_hash.first.restaurant_id, restaurant_address_id: orders_hash.first.restaurant_address_id, delivery_type: orders_hash.first.delivery_type, created_at: _current_time, from: invoice_from, to: invoice_to)
    else
      billing = company.billing
      unless billing.blank?
        bill_to = billing.addresses.pluck(:address_line, :city, :state, :zip).uniq.flatten.compact.join(", ")
        ship_to += billing.approvers.map{|a| "Approver: #{a.name}<br />#{a.addresses.map(&:formatted_address).flatten.compact.join(", ")}<br />"}.join(".<br />")
      end
      ship_to += Address.where(id: orders_hash.pluck(:address_id).uniq).map(&:formatted_address).flatten.compact.join(', ')
      ship_to += ".<br />"+Runningmenufield.find_by_sql("SELECT fields.name, ( CASE WHEN fields.field_type = '#{Field.field_types['dropdown']}' THEN STRING_AGG(DISTINCT fieldoptions.name, ', ') ELSE STRING_AGG(DISTINCT runningmenufields.value, ', ') END ) AS value FROM runningmenufields INNER JOIN fields ON fields.id = runningmenufields.field_id LEFT JOIN fieldoptions ON fieldoptions.id = runningmenufields.fieldoption_id WHERE runningmenufields.runningmenu_id IN ("+ orders_hash.pluck(:runningmenu_id).join(', ') +") GROUP BY fields.name, fields.field_type ").map{|of| "<strong>#{of.name}: </strong>#{of.value}"}.join("<br />")+"<br /><strong>Delivery Instructions: </strong>"+Runningmenu.where("id  IN ("+ orders_hash.pluck(:runningmenu_id).join(', ') +")").pluck(:delivery_instructions).compact.join(", ")
      delivery_fee = (billing.present? && billing.delivery_fee > 0) ? billing.delivery_fee : 29.99
      _current_time = Time.current.in_time_zone(company.time_zone)
      invoice = Invoice.create(skip_set_dates: true, company_id: company.id, bill_to: "#{billing.name}<br />#{bill_to}", ship_to: ship_to, ship_date: ordered_at, payment_terms: "Due Upon Receipt", due_date: _current_time, deliveries: deliveries, delivery_fee: delivery_fee, service_fee: (billing&.service_fee), created_at: _current_time, from: invoice_from, to: invoice_to)
    end
    Order.where(id: orders_hash.pluck(:order_id)).update_all(invoice_id: invoice.id)
    invoice.calculate_total_dues
    return invoice
  end

  def self.invoice_check
    puts "Invoice Check Start"
    first_invoice_runningmenu_deliver_at = ENV["START_TIME_INVOICE"].in_time_zone(Rails.application.config.time_zone)
    begin
      orders = Order.active.joins(:runningmenu => [:company => :billing]).where("runningmenus.delivery_at BETWEEN ? AND ?", first_invoice_runningmenu_deliver_at, Time.current - ENV["MISSING_INVOICE_MINUTES_AGO"].to_i.minute).where('billings.disable_auto_invoice = ?', false).where(invoice_id: nil).order(created_at: :desc)
      if orders.present?
        email = OrderMailer.invoice_check(orders)
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      end
    rescue StandardError => e
     puts "Invoice Check: #{e}"
    end
    puts "Invoice Check End"
  end

  def quickbooks_invoice_terms(setting, access_token)
    term_name = "Due on receipt"
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
        term.due_days = 0
        created_term = service.create(term)
        puts "###################################################### Created Invoice Term id is: "+created_term.id.to_s
        return created_term.id
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
      self.inform_finance(e.message)
    end
  end

  def upload_to_quickbook(invoice_id, setting, access_token)
    invoice = Invoice.find invoice_id
    delivery_li = invoice.line_items.find_by_item "Delivery & Service Fee"
    txn_date = invoice.from.blank? ? invoice.ship_date_timezone.strftime("%Y-%m-%d") : invoice.from_timezone.strftime("%Y-%m-%d")
    quantity = invoice.orders.sum(:quantity).to_f
    total = invoice.total_amount_due - delivery_li.amount
    qb_unit_price = (total/quantity).round 4
    begin
      qb_invoice = Quickbooks::Model::Invoice.new
      qb_invoice.customer_id = invoice.company.quickbooks_identity(setting, access_token)
      qb_invoice.txn_date = Date.civil(txn_date.to_date.year, txn_date.to_date.month, txn_date.to_date.day)
      qb_invoice.doc_number = invoice.invoice_number
      qb_invoice.due_date = invoice.due_date_timezone.strftime("%Y-%m-%d")
      if invoice.ship_to.include?("Invoice Email:") && !invoice.ship_to.split("<strong>Invoice Email:").last.split("</strong>").first.blank?
        qb_invoice.bill_email = Quickbooks::Model::EmailAddress.new(invoice.ship_to.split("<strong>Invoice Email:").last.split("</strong>").first)
      end
      qb_invoice.currency_ref = Quickbooks::Model::BaseReference.new('USD')
      qb_invoice.ship_date = invoice.from.blank? ? invoice.ship_date_timezone.strftime("%Y-%m-%d") : invoice.from_timezone.strftime("%Y-%m-%d")
      qb_invoice.sales_term_ref = Quickbooks::Model::BaseReference.new(invoice.quickbooks_invoice_terms(setting, access_token))
      shipping_address_hash = billing_address_hash = {}
      invoice.company.billing.addresses.pluck(:address_line, :city, :state, :zip).compact.uniq.each_with_index do |address, index|
        next if index > 4
        billing_address_hash["line"+((index+1).to_s)] = address.join(", ")
      end
      qb_invoice.billing_address = Quickbooks::Model::PhysicalAddress.new(billing_address_hash)
      if invoice.ship_to.split("<br />")[0].include? "Approver:"
        invoice.ship_to.split("<strong>")[0].split("<br />").each_with_index do |address, index|
          next if index == 0 || index > 5
          shipping_address_hash["line"+index.to_s] = address
        end
      else
        invoice.ship_to.split("<strong>")[0].split("<br />").each_with_index do |address, index|
          next if index > 4
          shipping_address_hash["line"+((index+1).to_s)] = address
        end
      end
      qb_invoice.shipping_address = Quickbooks::Model::PhysicalAddress.new(shipping_address_hash)
      line_item = Quickbooks::Model::InvoiceLineItem.new
      # line_item.amount = total
      line_item.amount = qb_unit_price*quantity
      line_item.description = "All fooditems charges except delivery fee"
      line_item.sales_item! do |detail|
        detail.unit_price = qb_unit_price
        detail.quantity = quantity
        detail.item_id = ENV["QB_ITEM"]
      end
      delivery_line_item = Quickbooks::Model::InvoiceLineItem.new
      # delivery_line_item.amount = delivery_li.amount
      delivery_line_item.amount = delivery_li.unit_price*delivery_li.quantity
      delivery_line_item.description = "Delivery fee charges"
      delivery_line_item.sales_item! do |detail|
        detail.unit_price = delivery_li.unit_price
        detail.quantity = delivery_li.quantity
        detail.item_id = ENV["QB_DELIVERY_ITEM"]
      end
      qb_invoice.line_items << line_item
      qb_invoice.line_items << delivery_line_item
      service = Quickbooks::Service::Invoice.new
      service.company_id = setting.realmid
      service.access_token = access_token
      created_invoice = service.create(qb_invoice)
      QuickbookLog.create!(upload_identity: invoice.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[0]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[0]], quickbook_identity: created_invoice.id)
      invoice.update_columns(total_amount_due_qb: (qb_unit_price*quantity)+(delivery_li.unit_price*delivery_li.quantity) )
      puts "###################################################### Created Invoice id is: "+created_invoice.id.to_s
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
      self.inform_finance(e.message)
    end
  end

  def set_calculation_at_qb(invoice)
    setting = Setting.latest
    access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
    service = Quickbooks::Service::Invoice.new
    service.company_id = setting.realmid
    service.access_token = access_token
    result = service.find_by(:doc_number, self.invoice_number)
    if result.first.present?
      old_invoice = result.first
      deleted_invoice = service.delete(old_invoice)
      if deleted_invoice
        other_line_items_amount = invoice.line_items.sum(:amount) - invoice.line_items.sum(:discount)
        txn_date = invoice.due_date
        quantity = invoice.orders.sum(:quantity).to_f
        total = invoice.total_amount_due - other_line_items_amount
        qb_unit_price = (total/quantity).round 4
        begin
          qb_invoice = Quickbooks::Model::Invoice.new
          qb_invoice.customer_id = invoice.company.quickbooks_identity(setting, access_token)
          qb_invoice.txn_date = Date.civil(txn_date.year, txn_date.month, txn_date.day)
          qb_invoice.doc_number = invoice.invoice_number
          qb_invoice.due_date = invoice.due_date.strftime("%Y-%m-%d")
          if invoice.ship_to.include?("Invoice Email:") && !invoice.ship_to.split("<strong>Invoice Email:").last.split("</strong>").first.blank?
            qb_invoice.bill_email = Quickbooks::Model::EmailAddress.new(invoice.ship_to.split("<strong>Invoice Email:").last.split("</strong>").first)
          end
          qb_invoice.currency_ref = Quickbooks::Model::BaseReference.new('USD')
          qb_invoice.ship_date = invoice.from.blank? ? invoice.ship_date.strftime("%Y-%m-%d") : invoice.from.strftime("%Y-%m-%d")
          qb_invoice.sales_term_ref = Quickbooks::Model::BaseReference.new(invoice.quickbooks_invoice_terms(setting, access_token))
          shipping_address_hash = billing_address_hash = {}
          invoice.company.billing.addresses.pluck(:address_line, :city, :state, :zip).compact.uniq.each_with_index do |address, index|
            next if index > 4
            billing_address_hash["line"+((index+1).to_s)] = address.join(", ")
          end
          qb_invoice.billing_address = Quickbooks::Model::PhysicalAddress.new(billing_address_hash)
          if invoice.ship_to.split("<br />")[0].include? "Approver:"
            invoice.ship_to.split("<strong>")[0].split("<br />").each_with_index do |address, index|
              next if index == 0 || index > 5
              shipping_address_hash["line"+index.to_s] = address
            end
          else
            invoice.ship_to.split("<strong>")[0].split("<br />").each_with_index do |address, index|
              next if index > 4
              shipping_address_hash["line"+((index+1).to_s)] = address
            end
          end
          qb_invoice.shipping_address = Quickbooks::Model::PhysicalAddress.new(shipping_address_hash)
          line_item = Quickbooks::Model::InvoiceLineItem.new
          # line_item.amount = total
          line_item.amount = qb_unit_price*quantity
          line_item.description = "All fooditems charges except delivery fee"
          line_item.sales_item! do |detail|
            detail.unit_price = qb_unit_price
            detail.quantity = quantity
            detail.item_id = ENV["QB_ITEM"]
          end
          qb_invoice.line_items << line_item

          other_line_item_total_qb = []
          invoice.line_items.each do |other_line_item|
            other_line_item_amount = other_line_item.amount - other_line_item.discount
            delivery_etc_line_item = Quickbooks::Model::InvoiceLineItem.new
            # delivery_etc_line_item.amount = other_line_item_amount
            other_li_unit_price = (other_line_item_amount/other_line_item.quantity).round 4
            other_line_item_total_qb << amount = other_line_item.quantity*other_li_unit_price
            delivery_etc_line_item.amount = amount
            delivery_etc_line_item.description = other_line_item.item.blank? ? "other line item" : other_line_item.item
            delivery_etc_line_item.sales_item! do |detail|
              detail.unit_price = other_li_unit_price
              detail.quantity = other_line_item.quantity
              detail.item_id = ENV["QB_DELIVERY_ITEM"]
            end
            qb_invoice.line_items << delivery_etc_line_item
          end

          service = Quickbooks::Service::Invoice.new
          service.company_id = setting.realmid
          service.access_token = access_token
          recreated_invoice = service.create(qb_invoice)
          QuickbookLog.create!(upload_identity: invoice.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[0]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[3]], quickbook_identity: recreated_invoice.id)
          invoice.update_columns(total_amount_due_qb: (qb_unit_price*quantity)+(other_line_item_total_qb.sum) )
          puts "###################################################### Recreated Invoice id is: "+recreated_invoice.id.to_s
        rescue StandardError => e
          puts "###################################################### Quickbook error: #{e.message}"
          self.inform_finance(e.message)
        end
      end
    end
  end

  def set_dates_at_qb
    begin
      setting = Setting.latest
      access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
      service = Quickbooks::Service::Invoice.new
      service.company_id = setting.realmid
      service.access_token = access_token
      result = service.find_by(:doc_number, self.invoice_number)
      if result.first.present?
        invoice = result.first
        invoice.ship_date = self.from.blank? ? self.ship_date.strftime("%Y-%m-%d") : self.from.strftime("%Y-%m-%d")
        invoice.due_date = self.due_date.strftime("%Y-%m-%d")
        upated_invoice = service.update(invoice, :sparse => true)
        QuickbookLog.create!(upload_identity: self.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[0]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[1]], quickbook_identity: upated_invoice.id)
        puts "###################################################### Updated Dates Invoice id is: "+upated_invoice.id.to_s
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
      self.inform_finance(e.message)
    end
  end

  def set_qb_status
    begin
      setting = Setting.latest
      access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
      service = Quickbooks::Service::Invoice.new
      service.company_id = setting.realmid
      service.access_token = access_token
      result = service.find_by(:doc_number, self.invoice_number)
      if result.first.present?
        invoice = result.first
        # invoice.line_items.each do |li|
        #   li.amount = 0.0
        #   unless li.sales_line_item_detail.nil?
        #     li.sales_line_item_detail.unit_price = 0.0
        #     li.sales_line_item_detail.quantity = 0.0
        #   end
        # end
        upated_invoice = service.update(invoice, :sparse => true)
        QuickbookLog.create!(upload_identity: self.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[0]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[1]], quickbook_identity: upated_invoice.id)
        puts "###################################################### Paid Invoice id is: "+upated_invoice.id.to_s
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
      self.inform_finance(e.message)
    end
  end

  def remove_from_quickbooks
    begin
      setting = Setting.latest
      access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
      service = Quickbooks::Service::Invoice.new
      service.company_id = setting.realmid
      service.access_token = access_token
      result = service.find_by(:doc_number, self.invoice_number)
      if result.first.present?
        invoice = result.first
        deleted_invoice = service.delete(invoice)
        if deleted_invoice
          QuickbookLog.create!(upload_identity: self.id, upload_type: QuickbookLog.upload_types[QuickbookLog.upload_types.keys[0]], event_type: QuickbookLog.event_types[QuickbookLog.event_types.keys[2]], quickbook_identity: invoice.id)
          puts "###################################################### Deleted Invoice id is: "+invoice.id
        end
      end
    rescue StandardError => e
      puts "###################################################### Quickbook error: #{e.message}"
      self.inform_finance(e.message)
    end
  end

  # def total_amount
  #   price_sum = self.orders.active.sum{|a| (a.total_price - a.user_paid)} + self.line_items.sum{|li| li.amount}
  #   discount_sum = self.orders.active.sum{|a| a.discount} + self.line_items.sum{|li| li.discount}
  #   price_sum - discount_sum
  # end

end
