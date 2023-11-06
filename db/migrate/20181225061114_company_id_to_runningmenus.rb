class CompanyIdToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_reference :runningmenus, :company, index: true, foreign_key: true, after: :runningmenu_type
  end
end
