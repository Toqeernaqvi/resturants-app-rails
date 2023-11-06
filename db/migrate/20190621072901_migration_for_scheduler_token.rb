class MigrationForSchedulerToken < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :share_token, :string, after: :deleted_cuisines
  end
end
