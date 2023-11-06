class AddAllowUsersToAdmin < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :allow_admin_to_manage_users, :boolean, default: true
  end
end
