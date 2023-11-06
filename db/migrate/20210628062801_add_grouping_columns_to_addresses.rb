class AddGroupingColumnsToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :grouping_rows, :integer, default: 6
    add_column :addresses, :grouping_columns, :integer, default: 5
  end
end
