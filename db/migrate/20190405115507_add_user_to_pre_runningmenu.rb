class AddUserToPreRunningmenu < ActiveRecord::Migration[5.1]
  def change
    Runningmenu.unscoped.each do |runningmenu|
      if runningmenu.runningmenu_request.present?
        runningmenu.update_columns( user_id: runningmenu.runningmenu_request.user_id )
      else
        runningmenu.update_columns( user_id: runningmenu.company.company_admins.first.id ) unless runningmenu.company.blank?
      end
    end
  end
end
