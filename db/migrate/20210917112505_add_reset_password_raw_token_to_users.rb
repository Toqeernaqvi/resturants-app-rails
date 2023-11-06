class AddResetPasswordRawTokenToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :reset_password_raw_token, :string
  end
end
