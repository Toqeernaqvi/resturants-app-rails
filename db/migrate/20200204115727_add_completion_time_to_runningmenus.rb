class AddCompletionTimeToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :completion_time, :datetime
  end
end
