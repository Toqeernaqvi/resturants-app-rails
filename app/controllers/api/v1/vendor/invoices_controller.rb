class Api::V1::Vendor::InvoicesController < Api::V1::Vendor::ApiController
  include SharedAdmin
  before_action :set_restaurant
  before_action :set_invoice, only: [:show, :update, :forward_invoice]

  def index
    from = params[:from].to_date.in_time_zone(current_member.time_zone).at_beginning_of_day
    to = params[:to].to_date.in_time_zone(current_member.time_zone).at_end_of_day
    @invoices_total = @restaurant.invoices.where(created_at: from..to).count
    @per_page = ENV['VENDOR_INVOICES_PER_PAGE']
    @invoices = @restaurant.invoices.where(created_at: from..to).order(created_at: :desc).page(params[:page]).per(@per_page)
  end

  def update
    if @invoice.update(invoice_params.merge(skip_set_dates: true))
      @invoice.reload
      render :show
    else
      error(E_INTERNAL, @invoice.errors.full_messages[0])
    end
  end

  def forwarded_invoice
    save_forwarded_email
    render :show
  end

  private

  def set_restaurant
    authorized_current_member = current_member.addresses_vendor.pluck(:address_id).include?(params["restaurant_id"].to_i) rescue nil
    if authorized_current_member.present?
      @restaurant = RestaurantAddress.find(params[:restaurant_id])
    else
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401      
    end
  end

  def set_invoice
    @invoice = @restaurant.invoices.find_by_id(params[:id] || params[:invoice_id])
    if @invoice.blank?
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
  end

  def invoice_params
    params.require(:invoice).permit(
      :bill_to,
      :ship_to,
      adjustments_attributes: [
        :id,
        :_destroy,
        :adjustment_date,
        :description,
        :adjustment_type,
        :price
      ]
    )
  end
end