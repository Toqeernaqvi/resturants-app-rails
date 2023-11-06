json.array! @meeting.share_meetings do |meeting|
  json.(
    meeting, :id, :first_name, :last_name, :name, :email, :user_id, :runningmenu_id, :token, :ordered
  )
end
