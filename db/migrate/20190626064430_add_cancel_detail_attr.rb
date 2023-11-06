class AddCancelDetailAttr < ActiveRecord::Migration[5.1]
  def change
    add_reference :runningmenus, :cancelled_by
    add_column :runningmenus, :cancelled_at, :datetime, after: :cancel_reason
  end
end
