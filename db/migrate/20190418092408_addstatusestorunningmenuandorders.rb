class Addstatusestorunningmenuandorders < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :parent_status, :integer, default: 0, after: :status
    add_column :orders, :parent_status, :integer, default: 0, after: :status
  end
end
