class AddColumnToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :unsubscribe_menu_ready_emails, :boolean, default: false
  end
end
