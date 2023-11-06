class Addappartmenttoaddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :task_id, :string, after: :runningmenu_type
  end
end
