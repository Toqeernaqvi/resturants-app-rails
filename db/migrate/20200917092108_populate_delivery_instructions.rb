class PopulateDeliveryInstructions < ActiveRecord::Migration[5.1]
  def change
    meetings = Runningmenu.joins(runningmenufields: [:field]).where(fields: { status: Field.statuses[:active]}).where("fields.name ILIKE '%delivery room%' AND runningmenufields.value IS NOT NULL AND runningmenufields.value != ''").select("runningmenus.*, runningmenufields.value AS delivery_room")
    recurring_meetings = RecurringScheduler.joins(runningmenufields: [:field]).where(fields: { status: Field.statuses[:active]}).where("fields.name ILIKE '%delivery room%' AND runningmenufields.value IS NOT NULL AND runningmenufields.value != ''").select("recurring_schedulers.*, runningmenufields.value AS delivery_room")
    unless meetings.blank?
      meetings.each do |meeting|
        meeting.update_column(:delivery_instructions, meeting.delivery_room)
      end
    end
    unless recurring_meetings.blank?
      recurring_meetings.each do |meeting|
        meeting.update_column(:delivery_instructions, meeting.delivery_room)
      end
    end
  end
end
