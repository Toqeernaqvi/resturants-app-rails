class RemoveBraintreeFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :charge_pending_amount_job_status, :integer, default: 0
    remove_column :users, :charge_pending_amount_job_error, :string
    remove_column :users, :pending_total, :decimal, default: 0, :precision => 8, :scale => 2
    remove_column :users, :attempts_count, :integer, default: 0
    remove_column :users, :valid_card, :boolean, default: true
    remove_column :users, :nonce, :string

    remove_column :share_meetings, :attempts_count, :integer, default: 0
    remove_column :share_meetings, :valid_card, :boolean, default: true
    remove_column :share_meetings, :payment_status, :integer, default: 0
    remove_column :share_meetings, :nonce, :string
    remove_column :share_meetings, :user_price, :decimal, default: 0, :precision => 8, :scale => 2

    remove_column :runningmenus, :user_pending_amount_job_id, :string
    remove_column :runningmenus, :user_pending_amount_job_status, :integer, default: 0
    remove_column :runningmenus, :user_pending_amount_job_error, :string

    remove_column :orders, :process , :integer, default: 0
    remove_column :orders, :payment_status, :integer, default: 0
  end
end
