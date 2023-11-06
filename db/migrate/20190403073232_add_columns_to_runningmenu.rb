class AddColumnsToRunningmenu < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :runningmenu_name, :string
    add_column :runningmenus, :per_meal_budget, :integer, default: 0
    add_reference :runningmenus, :user, index: true
    add_reference :runningmenurequestfields, :runningmenu, index: true
    add_reference :cuisines_requests, :runningmenu, index: true
  end
end
