ActiveAdmin.register Invoice do
  include SharedAdmin
  menu parent: 'Finance'
  config.clear_action_items!
  config.batch_actions = false
  actions :all, :except => [:new, :create, :destroy ]
    permit_params do
    permitted = [
      :bill_to,
      :ship_to,
      :payment_terms,
      :ship_date,
      :from,
      :to,
      :due_date,
      :status,
      line_items_attributes: [
        :id,
        :_destroy,
        :quantity,
        :item,
        :unit_price,
        :amount,
        :discount
      ]
    ]
  end
  action_item only: [:index] do
    link_to 'Create Manual Invoice', admin_manual_invoice_path, class: 'linksForScope'
  end
  index do
    # column :id
    column :invoice_number
    column :company
    column :restaurant_address do |i|
      link_to i.restaurant_address.name, admin_restaurant_address_path(restaurant_id: i.restaurant_id, id: i.restaurant_address_id) rescue nil
    end
    column :bill_to do |i|
      i.bill_to.html_safe
    end
    column :ship_to do |i|
      div do
        i.ship_to.html_safe
      end
    end
    # column :payment_terms
    # column :ship_date
    # column :delivery_fee
    column "Total" do |i|
      i.total_amount_due
    end
    column "Delivery Fee" do |i|
      # i.line_items.sum(:amount)
      i.delivery_fee_total
    end
    column "Ship Range" do |i|
      i.shipping
    end
    column "Due Date" do |i|
      i.due_date_timezone.strftime("%m/%d/%Y")
    end
    tag_column :status, interactive: true
    column 'Current Date' do |i|
      i.created_at_timezone.strftime("%m/%d/%Y %H:%M")
    end
    actions do |invoice|
      item(link_to 'PDF', generate_PDF_admin_invoice_path(id: invoice.id, format: :pdf), class: :member_link, :target => "_blank" )
      item('Charge Card', charge_card_admin_invoice_path(id: invoice.id), class: :member_link) if invoice.orders.active.exists? && invoice.company.billing.present? && invoice.company.billing.customer_id.present? && !invoice.paid? && !invoice.versions.exists?(["versions.object_changes LIKE ?", "%status:\n- #{Invoice.statuses[:paid]}%"])
      item("Forward", forward_invoice_admin_invoice_path(invoice.id), remote: true, class: [:member_link, :forwardInvoiceBtn])
      item('Delete', delete_admin_invoice_path(invoice.id), class: [:member_link, :delete_btn]) unless invoice.from.blank?
    end
  end

  csv do
    column :id
    column :invoice_number
    column "Company" do |i|
      i.company.name rescue ""
    end
    column :bill_to
    column :ship_to
    column "Total" do |i|
      i.total_amount_due
    end
    column "Delivery Fee" do |i|
      # i.line_items.sum(:amount)
      i.delivery_fee_total
    end
    column "Ship Range" do |i|
      i.shipping
    end
    column "Due Date" do |i|
      i.due_date_timezone.strftime("%m/%d/%Y")
    end
    column :status
    column 'Current Date' do |i|
      i.created_at_timezone.strftime("%m/%d/%Y %H:%M")
    end
  end


  form  do |f|
    f.input :bill_to, input_html: { rows: 4 }
    f.input :ship_to, input_html: { rows: 4 }
    # f.input :payment_terms, input_html: { rows: 4 }
    f.input :ship_date, as: :date_time_picker, input_html: { autocomplete: :off }
    f.input :from, as: :date_time_picker, input_html: { autocomplete: :off }
    f.input :to, as: :date_time_picker, input_html: { autocomplete: :off }
    f.input :due_date, as: :date_time_picker, input_html: { autocomplete: :off }
    f.input :status

    f.has_many :line_items do |li|
      li.input :quantity
      li.input :item
      li.input :unit_price
      li.input :amount
      li.input :discount
    end

    f.actions do
      f.action(:submit)
      f.cancel_link
    end
  end

  action_item only: [:show] do
    link_to 'PDF', generate_PDF_admin_invoice_path(id: resource.id, format: :pdf), class: :member_link , :target=> "_blank"
  end

  show do
    attributes_table do
      # row :id
      row :invoice_number
      row :bill_to do |i|
        i.bill_to.html_safe
      end
      row :ship_to do |i|
        i.ship_to.html_safe
      end
      # row :payment_terms
      # row :ship_date
      row 'Ship Range' do |i|
        i.shipping
      end
      row :due_date { |c| c.due_date_timezone.strftime("%m/%d/%Y") }
      row :status
      row 'Current Date' do |c|
        c.created_at_timezone.to_time.strftime('%B %d, %Y')
      end
      ol 'Line items', :class => "wrapper_optionset" do
        render partial: 'line-items', locals: { resource: resource }
      end
      panel "Audit log" do
        render partial: '/active_admin/versions/invoice_model', locals: {versions: (resource.versions.includes(:item)+PaperTrail::Version.joins(:version_associations).where("version_associations.foreign_key_id = ? AND version_associations.foreign_type = ?",resource.id,"Invoice").includes(:item)).sort_by(&:created_at).reverse}
      end
    end
  end

  collection_action :filtered_company, method: :post do
    if params[:from].present? && params[:to].present? && params[:company_id].present?
      result = Invoice.generate_company_invoice(params[:from], params[:to], params[:company_id])
      if result.first > 0
        redirect_to admin_manual_invoice_path(invoice_ids: result.last), notice: "Invoices have been successfully generated"
      else
        redirect_to admin_invoices_path, alert: "No orders found to generate invoice"
      end
    else
      redirect_to admin_manual_invoice_path, alert: "All fields are required in order to create invoices."
    end
  end

  member_action :delete, method: :get do
    invoice = Invoice.find(params[:id])
    invoice.orders.update_all(invoice_id: nil)
    if invoice.destroy
      redirect_to admin_invoices_path, notice: "Invoice has been successfully deleted"
    else
      redirect_to admin_invoices_path, alert: "Invoice not deleted"
    end
  end

  member_action :download_PDF, method: :get do
    @invoice = Invoice.find_by_id params[:id]
    file_name = "Chowmill-#{@invoice.charged_cc ? 'Receipt' : 'Invoice'}-#{@invoice.shipping}-#{@invoice.invoice_number}".gsub!('/','-')
    pdf = render_to_string(pdf: file_name, template: 'admin/invoices/invoice.html.erb', :formats => [:html], :layout => false, :locals => {:invoice => @invoice}, margin: {
          top: 50,
          bottom: 5
      }, header: { html: {template: 'admin/invoices/invoice_header'} }, encoding: 'binary')
    send_data(pdf, :type => 'application/pdf', :filename => file_name, :disposition => "attachment")
  end

  member_action :generate_PDF, method: :get do
    # resource.update_attribute(:due_date, Time.current)
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "Chowmill Invoice #{resource.shipping}-#{resource.invoice_number}", template: 'admin/invoices/invoice.html.erb', locals: { invoice: resource}, margin: {
              top: 45,
              left: 5,
              right: 5,
              bottom: 5
          }, header: { html: {template: 'admin/invoices/invoice_header'} }, :disposition => :inline,  encoding: 'binary'

      end
      # if request.get?
      #   resource.update_attributes(status: 0)
      # end
    end
  end

  member_action :forward_invoice, method: :get do
    @invoice = Invoice.find(params[:id])
    @card_last_four_digits = (@invoice.company&.billing&.retreive_card)&.last4 rescue nil
    @forward_invoice_body = render_to_string("forward_invoice_body", :formats => [:html], :layout => false, :locals => {:invoice => @invoice})
    respond_to do |format|
      format.js { render "forward_invoice" }
    end
  end

  collection_action :company_last_invoice_date, method: :post do
    company = Company.find params[:company_id]
    date = company.invoices.order(created_at: :asc).last.created_at_timezone.strftime("%Y/%m/%d %H:%M") rescue company.created_at.strftime("%Y/%m/%d %H:%M")
    render json: {last_invoice_date: date}
  end

  collection_action :company_current_date, method: :get do
    company = Company.find params[:company_id]
    date = Time.current.in_time_zone(company.time_zone).strftime("%Y/%m/%d")
    render json: {company_current_date: date}
  end

  collection_action :forwarded_invoice, method: :post do
    save_forwarded_email
    flash[:notice] = "Invoice forwarded successfully."
    redirect_to admin_invoices_path
  end

  member_action :charge_card, method: :get do
    # price_sum = resource.orders.sum{|a| a.total_price - a.user_paid} + resource.line_items.sum{|li| li.amount}
    # discount_sum = resource.orders.sum{|a| a.discount} + resource.line_items.sum{|li| li.discount}
    # total_amount = (price_sum - discount_sum).to_f
    begin
      charge = Stripe::Charge.create({
  		  amount: ((resource.total_amount - resource.total_discount) * 100).to_i,
  		  currency: "usd",
  		  customer: resource.orders.first.runningmenu.company.billing.customer_id,
        metadata: {invoice: resource.invoice_number},
  		})
      if charge.present? && charge.paid
        resource.update(status: :paid, charged_cc: true, paid_date: Time.current.in_time_zone(resource.company.time_zone), skip_validate_status: true)
        payment_log = PaymentLog.create(company: resource.orders.first.runningmenu.company, amount: resource.total_amount_due, refund_amount: resource.total_amount_due, payment_gateway: PaymentLog.payment_gateways[:stripe], status: PaymentLog.statuses[:success], message: "Transaction successfully processed.", transaction_id: charge.id, email: '', sales_receipt: true, invoice_number: resource.id)
        payment_log.orders << resource.orders
        redirect_to admin_invoices_path, notice: "Company charged successfully"
      else
        redirect_to admin_invoices_path, notice: "Company charged failed due to some reason."
      end
    rescue => e
      redirect_to admin_invoices_path, notice: "Company charged failed due to #{e}"
    end
  end

  filter :invoice_number, label: "Invoice No"
  filter :status, as: :select, collection: -> {Invoice.statuses}
  filter :company_in, label: "Company", as: :select, collection: proc{ Company.active.pluck(:name, :id) }
  filter :bill_to
  filter :ship_to
  filter :ship_date, as: :date_range
  filter :from
  filter :to
  filter :due_date, as: :date_range
  filter :created_at, label: "Current Date", as: :date_range

  controller do
    before_action :set_paper_trail_whodunnit
    skip_before_action :verify_authenticity_token, :only => [:update, :company_last_invoice_date]
    skip_around_action :set_admin_timezone, except: [:index]

    def scoped_collection
      Invoice.includes(:company, :restaurant, :restaurant_address, :orders)
    end

    def edit
      resource.ship_date = resource.ship_date.in_time_zone(resource.company.time_zone).strftime("%a, %d %B %Y %H:%M:%S")
      resource.from = resource.from&.in_time_zone(resource.company.time_zone)&.strftime("%a, %d %B %Y %H:%M:%S")
      resource.to = resource.to&.in_time_zone(resource.company.time_zone)&.strftime("%a, %d %B %Y %H:%M:%S")
      resource.due_date = resource.due_date.in_time_zone(resource.company.time_zone).strftime("%a, %d %B %Y %H:%M:%S")
    end
  end

end
