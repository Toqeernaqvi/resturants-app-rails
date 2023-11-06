class AddRunningmenuApproveStatusToRunningmenu < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :status, :integer, default: 0, after: :admin_cutoff_at
  end
end
