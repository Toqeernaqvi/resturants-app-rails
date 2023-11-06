class RemoveRunningmenuRequestFromRunningmenu < ActiveRecord::Migration[5.1]
  def change
    remove_reference :runningmenus, :runningmenu_request, index: true, foreign_key: true, after: :runningmenu_request_type
  end
end
