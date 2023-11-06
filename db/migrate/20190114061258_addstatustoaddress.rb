class Addstatustoaddress < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :status, :integer, default: 0, after: :name
    rename_column :addresses, :name, :address_line
  end
end
