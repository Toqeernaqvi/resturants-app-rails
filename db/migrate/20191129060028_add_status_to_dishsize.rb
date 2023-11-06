class AddStatusToDishsize < ActiveRecord::Migration[5.1]
  def change
    add_column :dishsizes, :status, :integer, default: 0
    add_column :dishsizes, :parent_status, :integer, default: 0
  end
end
