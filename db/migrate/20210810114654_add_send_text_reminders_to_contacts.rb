class AddSendTextRemindersToContacts < ActiveRecord::Migration[5.1]
  def change
    add_column :contacts, :send_text_reminders, :boolean, default: true
    add_column :users, :send_text_reminders, :boolean, default: true
  end
end
