# app/controllers/api/v1/addresses_controller.rb
class Api::V1::CompaniesController < Api::V1::ApiController
  skip_before_action :authenticate_active_user, if: lambda { params[:token].present?}
  before_action :set_share_meeting, if: lambda { params[:token].present?}
  before_action :set_meeting, only: [:index], if: lambda { params[:slug].present?}

  def index
  end

  def billing
    if current_member.company.billing.update(billing_params)
      current_member.company.billing.remove_card if billing_params[:delete_stripe_card].present? && billing_params[:delete_stripe_card]
      render json: {message: 'Billing updated successfully'}
    else
      error(E_INTERNAL, current_member.company.billing.errors.full_messages[0])
    end
  end

  def meetings
    set_params
    if current_member.company_admin?
      @meetings =  Runningmenu.approved.distinct.joins(:orders).where("orders.status =?", Order.statuses[:active]).where(company_id: current_member.company_id, delivery_at: @from..@to).order(:delivery_at).page(params[:page]).per(10)
      @meetings_count = Runningmenu.approved.distinct.joins(:orders).where("orders.status =?", Order.statuses[:active]).where(company_id: current_member.company_id, delivery_at: @from..@to).count
    elsif current_member.company_user? || current_member.company_manager? || current_member.unsubsidized_user?
      @meetings =  Runningmenu.approved.distinct.joins(:orders).where("orders.status =? AND orders.user_id = ?", Order.statuses[:active], current_member.id).where(company_id: current_member.company_id, delivery_at: @from..@to).order(:delivery_at).page(params[:page]).per(10)
      @meetings_count = Runningmenu.approved.distinct.joins(:orders).where("orders.status =? AND orders.user_id = ?", Order.statuses[:active], current_member.id).where(company_id: current_member.company_id, delivery_at: @from..@to).count
    end
  end

  def future_meeting
    @tags_query = " AND ((SELECT COUNT(*) < 1 FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = runningmenus.id AND taggings.taggable_type = 'Runningmenu')
    OR (SELECT (COUNT(*) > 0) FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = runningmenus.id AND taggings.taggable_type = 'Runningmenu' AND tags.id IN(SELECT tags.id FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = #{current_member.id} AND taggings.taggable_type = 'User')))"
    where_str = "runningmenus.company_id = #{current_member.company_id} AND runningmenus.delivery_at > '#{Time.current.utc.to_s(:db)}' AND runningmenus.address_id = #{current_member.address_id}"
    if current_member.company_user? || current_member.company_manager? || current_member.unsubsidized_user?
      where_str += " AND cutoff_at > '#{Time.current.utc.to_s(:db)}'"
      where_str += @tags_query
    else
      where_str += " AND admin_cutoff_at > '#{Time.current.utc.to_s(:db)}'"
    end
    meeting = Runningmenu.approved.where(where_str).select(:id, :slug, :delivery_at).order(delivery_at: :asc).first
    if params[:menu].present? && meeting.blank?
      render_other_meeting
    else
      render_json_meeting meeting
    end
  end

  def childs
    @companies_list = []
    companies = current_member.company.childs.active
    if companies.blank?
      companies = [current_member.company]
    end
    companies.each do |company|
      @companies_list << company
      company.addresses.active.each do |address|
        @companies_list << address
      end
    end
  end

  def send_invoice_email
    @invoice = Invoice.find_by_id(params[:invoice_id])
    if @invoice.present?  
      render pdf: "Chowmill Invoice #{@invoice.shipping}-#{@invoice.invoice_number}", template: 'admin/invoices/invoice.html.erb', locals: { invoice: @invoice}, margin: {
        top: 45,
        left: 5,
        right: 5,
        bottom: 5
      }, header: { html: {template: 'admin/invoices/invoice_header'} }, :disposition => :inline,  encoding: 'binary', message: "Success"
    else
      render json: {message: "No orders yet"}, status: 403
    end
  end

  private
  def set_share_meeting
    @share_meeting = ShareMeeting.find_by(token: params[:token])
  end

  def set_params
    if params[:from].present? && params[:to].present?
      @from = params[:from].to_date.in_time_zone(current_member.company.time_zone).at_beginning_of_day
      @to = params[:to].to_date.in_time_zone(current_member.company.time_zone).at_end_of_day
    else
      default_runningmenu = Runningmenu.approved.where(company_id: current_member.company_id).where('delivery_at >= ?', Time.current.at_beginning_of_day).order(:delivery_at).first
      if default_runningmenu.blank?
        default_runningmenu = Runningmenu.approved.where(company_id: current_member.company_id).where('delivery_at < ?', Time.current.at_beginning_of_day).order(:delivery_at).last
      end
      @from = default_runningmenu.blank? ? Time.current - Time.current.wday.day : default_runningmenu.delivery_at - default_runningmenu.delivery_at.wday.day
      @to = @from + 6.days
    end
  end

  def render_other_meeting
    where_str = "runningmenus.company_id = #{current_member.company_id} AND runningmenus.delivery_at > '#{Time.current.utc.to_s(:db)}'"
    if current_member.company_user? || current_member.company_manager? || current_member.unsubsidized_user?
      where_str += " AND cutoff_at > '#{Time.current.utc.to_s(:db)}'"
      where_str += @tags_query
    else
      where_str += " AND admin_cutoff_at > '#{Time.current.utc.to_s(:db)}'"
    end
    meeting = Runningmenu.approved.where(where_str).select(:id, :slug, :delivery_at).order(delivery_at: :asc).first
    if meeting.blank?
      render_cutoff_passed_meeting
    else
      render_json_meeting meeting
    end
  end

  def render_cutoff_passed_meeting
    where_str = "runningmenus.company_id = #{current_member.company_id} AND runningmenus.delivery_at > '#{Time.current.utc.to_s(:db)}'"
    if current_member.company_user? || current_member.company_manager? || current_member.unsubsidized_user?
      where_str += @tags_query
    end
    meeting = Runningmenu.approved.where(where_str).select(:id, :slug, :delivery_at).order(delivery_at: :asc).first
    if meeting.blank?
      render_delivery_passed_meeting
    else
      render_json_meeting meeting
    end
  end

  def render_delivery_passed_meeting
    where_str = "runningmenus.company_id = #{current_member.company_id} AND runningmenus.delivery_at <= '#{Time.current.utc.to_s(:db)}'"
    if current_member.company_user? || current_member.company_manager? || current_member.unsubsidized_user?
      where_str += @tags_query
    end
    meeting = Runningmenu.approved.where(where_str).select(:id, :slug, :delivery_at).order(delivery_at: :asc).first
    render_json_meeting meeting
  end

  def render_json_meeting meeting
    meeting = meeting.present? ? { id: meeting.id, slug: meeting.slug, delivery_at: meeting.delivery_at} : meeting
    render json: {meeting: meeting}
  end

  def set_meeting
    @meetings_exists = false
    unless current_member.company_admin?
      @meeting = Runningmenu.find_by_slug(params[:slug])
      if @meeting.blank?
        render json: {message: "Invalid meeting."}
      else
        @meetings_exists = current_member.company.runningmenus.approved.joins(:orders).where("runningmenus.id != ?", @meeting.id).where(delivery_at: @meeting.delivery_at, orders: {status: :active, user_id: current_member.id}).exists?
      end
    end
  end

  def billing_params
    params.require(:billing).permit(
        :id,
        :token,
        :delete_stripe_card,
        :invoice_credit_card,
        :name,
        addresses_attributes: [
          :id,
          :_destroy,
          :address_line,
          :city,
          :state,
          :zip,
        ],
        approvers_attributes: [
          :id,
          :name,
          :email,
        ],
    )
  end
end
