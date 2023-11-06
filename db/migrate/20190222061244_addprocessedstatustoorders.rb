class Addprocessedstatustoorders < ActiveRecord::Migration[5.1]
  def change
    remove_column :runningmenus, :charged_status , :integer, default: 0
    add_column :orders, :process , :integer, default: 0, after: :remarks
  end
end
