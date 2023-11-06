class AddAdminContactToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :admin_office_phone, :string, after: :address_id
  end
end
