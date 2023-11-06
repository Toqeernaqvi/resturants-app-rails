class ChangeColumnBilling < ActiveRecord::Migration[5.1]
  def change
      change_column :billings, :weekly_invoice, :integer, default: 0
  end
end
