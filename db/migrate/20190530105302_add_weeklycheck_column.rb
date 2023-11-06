class AddWeeklycheckColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :weekly_invoice, :integer
  end
end
