class AddStripeConnectAttrs < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :stripe_acc_id, :string
    add_column :addresses, :stripe_acc_link, :string
    add_column :addresses, :stripe_acc_login, :string
    add_column :users, :stripe_admin, :boolean, default: false
    add_column :restaurant_billings, :stripe_payout_id, :string
  end
end
