class AddWeeklyCheckToBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :billings, :weekly_invoice, :integer
    remove_column :companies, :weekly_invoice, :integer
  end
end
