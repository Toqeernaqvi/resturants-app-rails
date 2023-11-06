class AddSharedMeetingIdToOrders < ActiveRecord::Migration[5.1]
  def change
    add_reference :orders, :share_meeting
  end
end
