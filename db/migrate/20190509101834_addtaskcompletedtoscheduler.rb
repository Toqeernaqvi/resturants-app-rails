class Addtaskcompletedtoscheduler < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :task_completed, :boolean, default: false, after: :task_id
  end
end
