class CompaniesCopay < ActiveRecord::Migration[5.1]
  def up
    add_column :companies, :short_code, :string, after: :name
    change_column :companies, :copay_amount, :decimal, precision: 15, scale: 2, default: "0.0"
  end
  def down
    remove_column :companies, :short_code, :string, after: :name
    change_column :companies, :copay_amount, :integer, default: "0"
  end
end
