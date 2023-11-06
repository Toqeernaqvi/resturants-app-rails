# json.approved @approvedrunningmenus do |delivery_at|
#   json.delivery_at delivery_at.in_time_zone(current_member.company.time_zone)
# end

# json.green_approved @greenapprovedrunningmenus do |delivery_at|
#   json.delivery_at delivery_at.in_time_zone(current_member.company.time_zone)
# end

# json.futureday_approved @futureday_runningmenus do |delivery_at|
#   json.delivery_at delivery_at.in_time_zone(current_member.company.time_zone)
# end

# json.pending @pendingrunningmenus do |delivery_at|
#   json.delivery_at delivery_at.in_time_zone(current_member.company.time_zone)
# end

# json.futureday_pending @futureday_pending_runningmenus do |delivery_at|
#   json.delivery_at delivery_at.in_time_zone(current_member.company.time_zone)
# end
# json.default @default_runningmenu.nil? ? Time.current.in_time_zone(current_member.company.time_zone) - Time.current.in_time_zone(current_member.company.time_zone).wday.day : @default_runningmenu.delivery_at.in_time_zone(current_member.company.time_zone) - @default_runningmenu.delivery_at.in_time_zone(current_member.company.time_zone).wday.day

# json.past_approved @pastapprovedrunningmenus do |delivery_at|
#   json.delivery_at delivery_at.in_time_zone(current_member.company.time_zone)
# end

# json.past_not_approved @pastnotapprovedrunningmenus do |delivery_at|
#   json.delivery_at delivery_at.in_time_zone(current_member.company.time_zone)
# end