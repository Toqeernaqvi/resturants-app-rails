class AddUserPriceToSharemeeting < ActiveRecord::Migration[5.1]
  def change
    add_column :share_meetings, :user_price, :decimal, default: 0, :precision => 8, :scale => 2
    add_column :share_meetings, :customer_id, :bigint, after: :runningmenu_id
    add_column :share_meetings, :nonce, :string, after: :customer_id
    add_column :share_meetings, :payment_status, :integer, default: 0, after: :customer_id

    add_column :payment_logs, :email, :string, after: :message
  end
end
