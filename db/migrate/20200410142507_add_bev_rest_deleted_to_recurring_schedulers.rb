class AddBevRestDeletedToRecurringSchedulers < ActiveRecord::Migration[5.1]
  def change
  	add_column :recurring_schedulers, :bev_rest_deleted, :boolean, default: false
  end
end
