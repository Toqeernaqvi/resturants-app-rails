class AddEnableGroupingOrdersToCompany < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :enable_grouping_orders, :boolean, default: false
  end
end
