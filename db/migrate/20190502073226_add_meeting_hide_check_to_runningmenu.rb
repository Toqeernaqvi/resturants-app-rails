class AddMeetingHideCheckToRunningmenu < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :hide_meeting, :boolean, after: :parent_status
  end
end
