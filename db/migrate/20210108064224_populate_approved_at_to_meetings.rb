class PopulateApprovedAtToMeetings < ActiveRecord::Migration[5.1]
  def change
    Runningmenu.approved.where("delivery_at >= ? AND approved_at IS NULL", Time.current).each do |meeting|
      meeting.update_column(:approved_at, meeting.created_at)
    end
  end
end
