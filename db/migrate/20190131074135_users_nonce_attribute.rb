class UsersNonceAttribute < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :nonce, :string, after: :status
  end
end
