# app/controllers/api/v1/menus_controller.rb
class Api::V1::MenusController < Api::V1::ApiController
  skip_before_action :authenticate_active_user, if: lambda { params[:token].present? }
  before_action :set_share_meeting, if: lambda { params[:token].present? }
  before_action :set_runningmenu, only: [:index, :orders, :dynamic_sections]

  # GET /schedules/:id/addresses/:id/menus
  def index
    if @runningmenu.blank?
      error(E_INTERNAL, 'No menu defined')
    elsif params[:token].present? && @share_meeting.blank?
      error(E_INTERNAL, 'Meeting is not shared with this user')
    else
      p_params = "p_s3_base_url := 'https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com'::TEXT, p_runningmenu_id := #{@runningmenu.id}, p_company_id := #{@runningmenu.company_id}"
      if current_member.present?
        p_params += ", p_current_user_id := #{current_member.id}"
      end
      if @share_meeting.present?
        p_params += ", p_share_meeting_id := #{@share_meeting.id}"
      end
      if params[:r].present?
        p_r = params[:r].join(",")
        p_params += ", p_r:= '#{p_r}'"
      end
      if params[:d].present?
        p_d = params[:d].join(",")
        p_params += ", p_d:= '#{p_d}'"
      end
      if params[:i].present?
        p_i = params[:i].join(",")
        p_params += ", p_i:= '#{p_i}'"
      end
      sql = "SELECT * FROM menus(#{p_params})"
      menus = ActiveRecord::Base.connection.execute(sql)
      render json: FetchMenus.call(current_member, menus.first["menus"])
    end
  end

  def dynamic_sections
    # binding.pry
  end

  # GET /menus/schedules
  def schedules
    # @schedule = Runningmenu.approved
    #   .where(company_id: current_member.company.id)
    #   .where(delivery_at: Time.current..Time.current + 28.days)
    #   .where('activation_at <= ?', Time.current)
    #   .order(delivery_at: :asc)
    #   .limit(1)

    # user = @share_meeting.present? ? @share_meeting.user : current_member
    # @company = @share_meeting.present? ? @share_meeting.runningmenu.company : current_member.company
    # @schedule = Runningmenu.approved.joins(:address)
    # .where('addresses.status = ?', Address.statuses[:active])
    # .where(user.company_user? ? 'runningmenus.hide_meeting = ?' : '', false )
    # .where(user.company_user? ? 'cutoff_at > ?' : 'admin_cutoff_at > ?',Time.current)
    # .where('delivery_at > ?', Time.current)
    # .where(company_id: @company.id)
    # .order("DATE(delivery_at) ASC")
    # .limit(1)

    # if @schedule.blank?
    #   @schedule = Runningmenu.approved.joins(:address)
    #   .where('addresses.status = ?', Address.statuses[:active])
    #   .where(user.company_user? ? 'runningmenus.hide_meeting = ?' : '', false )
    #   .where('DATE(delivery_at) >= ?', Time.current.to_date)
    #   .where(company_id: @company.id)
    #   .order("DATE(delivery_at) ASC")
    #   .limit(1)
    # end

    # @first_pending_delivery
    # if @schedule.blank?
    #   @first_pending_delivery = Runningmenu.pending.joins(:address)
    #   .where('addresses.status = ?', Address.statuses[:active])
    #   .where(user.company_user? ? 'runningmenus.hide_meeting = ?' : '', false )
    #   .where(company_id: @company.id)
    #   .where('delivery_at > ?', Time.current)
    #   .order("delivery_at ASC").pluck(:delivery_at).first
    # end

    # @schedules = Runningmenu.approved.joins(:address).select('runningmenus.id, runningmenu_type, address_id, delivery_at, DATE_FORMAT(delivery_at, "%Y-%m-%d") AS date, DATE_FORMAT(delivery_at, "%Y") AS year, DATE_FORMAT(delivery_at, "%m") AS month, DATE_FORMAT(delivery_at, "%d") AS day')
    #   .where('addresses.status = ?', Address.statuses[:active])
    #   .where(company_id: @company.id)
    #   .where(delivery_at: Time.current..Time.current + 28.days)
    #   .where('activation_at <= ?', Time.current)
    #   .order(delivery_at: :asc)

    # @booked = Order.active.select('runningmenu_id, orders.address_id, delivery_at, DATE_FORMAT(ordered_at, "%Y-%m-%d") AS date, DATE_FORMAT(ordered_at, "%Y") AS year, DATE_FORMAT(ordered_at, "%m") AS month, DATE_FORMAT(ordered_at, "%d") AS day')
    #   .joins(:runningmenu)
    #   .where(user_id: current_member.id)
    #   .where(company_id: current_member.company_id)
    #   .where(ordered_at: Time.current..Time.current + 28.days)
    #   .group(:runningmenu_id, :address_id, :date, :year, :month, :day)
  end

  private
  def set_runningmenu
    @runningmenu = Runningmenu.approved.find_by_slug params[:schedule_id]
    if @share_meeting.present?
      @runningmenu = @share_meeting.runningmenu
    end
    unless @runningmenu.present?
      error(E_INTERNAL, 'Unable to find scheduler')
    end
  end
  def set_share_meeting
    @share_meeting = ShareMeeting.find_by(token: params[:token])
    unless @share_meeting.present?
      error(E_INTERNAL, 'Unable to find shared meeting')
    end
  end
end
