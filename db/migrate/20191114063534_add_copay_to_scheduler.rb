class AddCopayToScheduler < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :per_user_copay, :integer, default: 0
    add_column :runningmenus, :per_user_copay_amount, :decimal, precision: 15, scale: 2, default: "0.0"
  end
end
