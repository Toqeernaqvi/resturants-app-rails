class UsersFrontendToken < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :frontend_login_token, :string, after: :pending_total
  end
end
