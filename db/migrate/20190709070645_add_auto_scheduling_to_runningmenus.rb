class AddAutoSchedulingToRunningmenus < ActiveRecord::Migration[5.1]
  def change
  	add_column :runningmenus, :auto_scheduling, :boolean
  end
end
