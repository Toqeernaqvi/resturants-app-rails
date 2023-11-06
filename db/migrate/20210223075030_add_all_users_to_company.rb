class AddAllUsersToCompany < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :allow_users_to_onboard_without_admin_approval, :boolean, default: false
  end
end
