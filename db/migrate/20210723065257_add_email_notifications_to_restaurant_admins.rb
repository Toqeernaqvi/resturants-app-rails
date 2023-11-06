class AddEmailNotificationsToRestaurantAdmins < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :fax, :string
    add_column :users, :email_summary_check, :boolean, default: true
    add_column :users, :fax_summary_check, :boolean, default: true
    add_column :users, :email_label_check, :boolean, default: true
  end
end
