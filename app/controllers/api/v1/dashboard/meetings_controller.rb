class Api::V1::Dashboard::MeetingsController < Api::V1::ApiController
  before_action :init_sort
  before_action :set_tags_query, only: [:your_locations, :other_locations]

  def your_deliveries
    @runningmenus = ViewDelivery.where(company_id: current_member.company_id, delivery_at: @from..@to).order("#{@sort_by} #{@sort_order}").page(params[:page]).per(@per_page)
  end

  def delivery_requests
    @runningmenus = Runningmenu.pending.joins(:company, :address).where(company_id: current_member.company_id, delivery_at: @from..@to).order("#{@sort_by} #{@sort_order}")#.page(params[:page]).per(@per_page)
  end

def your_locations
    where_str = "hide_meeting = false OR (share_meetings.email = '#{current_member.email}' AND delivery_at > NOW() AND cutoff_at > NOW())"
    @runningmenus = Runningmenu.approved.joins(:company, :address).left_joins(orders: :share_meeting).where(where_str).where(@tags_query).where(address_id: current_member.address_id, delivery_at: @from..@to).distinct.order("#{@sort_by} #{@sort_order}").page(params[:page]).per(@per_page)
  end

  def other_locations
    where_str = "hide_meeting = false OR (share_meetings.email = '#{current_member.email}' AND delivery_at > NOW() AND cutoff_at > NOW())"
    @runningmenus = Runningmenu.approved.joins(:company, :address).left_joins(:share_meetings).where(where_str).where(@tags_query).where(company_id: current_member.company_id, delivery_at: @from..@to).where.not(address_id: current_member.address_id).distinct.order("#{@sort_by} #{@sort_order}").page(params[:page]).per(@per_page)
  end

  private

  def init_sort
  	@from = params[:from].to_date.in_time_zone(current_member.company.time_zone).at_beginning_of_day
    @to = params[:to].to_date.in_time_zone(current_member.company.time_zone).at_end_of_day
    @per_page = ENV['DELIVERIES_PER_PAGE']
    @sort_order = (params[:sort_order].present? && ['asc', 'desc'].include?(params[:sort_order].downcase)) ? params[:sort_order] : "ASC"
    @sort_by = (params[:sort_by].present? && ['delivery_at', 'formatted_address', 'total_quantity'].include?(params[:sort_by])) ? params[:sort_by] : "delivery_at"
  end

  def set_tags_query
    @tags_query = "((SELECT COUNT(*) < 1 FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = runningmenus.id AND taggings.taggable_type = 'Runningmenu') OR (SELECT (COUNT(*) > 0) FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = runningmenus.id AND taggings.taggable_type = 'Runningmenu' AND tags.id IN(SELECT tags.id FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = #{current_member.id} AND taggings.taggable_type = 'User')))"
  end

end