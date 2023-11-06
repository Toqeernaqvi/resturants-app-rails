class Api::V1::Vendor::LogsController < Api::V1::Vendor::ApiController
  def freshdesk_logs
    @freshdesklogs = FreshDeskLog.where(:requester=>current_member.id.to_s, :widget_type=>FreshDeskLog.widget_types.keys[0])
  end
end