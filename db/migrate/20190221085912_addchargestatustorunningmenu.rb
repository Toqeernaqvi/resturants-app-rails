class Addchargestatustorunningmenu < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :charged_status , :integer, default: 0
  end
end
