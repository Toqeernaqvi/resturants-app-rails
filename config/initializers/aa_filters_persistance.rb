module ActiveAdmin
  module FiltersPersistance
    extend ActiveSupport::Concern

    CLEAR_FILTERS = "clear_filters"
    FILTER        = "Filter"

    included do
      before_action :resolve_filters
    end

    private

    def resolve_filters
      session_key = "#{controller_name}_q".to_sym

      if session[session_key].present? &&  params[:q].present? && params[:q][:top_filter].present?
        params[:q] = session[session_key].to_a.push(["by_days_in", params[:q][:by_days_in]]).to_h
      end

      if params[:commit] == CLEAR_FILTERS
        session.delete(session_key)
      elsif (params[:q] || params[:commit] == FILTER) && action_name.inquiry.index?
        session[session_key] = params[:q]
      elsif session[session_key] && action_name.inquiry.index?
        params[:q] = session[session_key]
      end
    end
  end
end
