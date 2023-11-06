class ChangeColumnUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :menu_ready_email, :boolean, default: true
    remove_column :users, :unsubscribe_menu_ready_emails
  end
end
