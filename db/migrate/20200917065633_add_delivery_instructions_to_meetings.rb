class AddDeliveryInstructionsToMeetings < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :delivery_instructions, :text
    add_column :recurring_schedulers, :delivery_instructions, :text
  end
end
