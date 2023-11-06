class AddCancelReasonToScheduler < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :cancel_reason, :text, after: :deleted_cuisines
  end
end
