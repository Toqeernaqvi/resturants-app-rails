class ChangeColumnTypeMetrics < ActiveRecord::Migration[5.1]
  def up
    change_column :dashboard_metrics, :data, :longtext
  end

  def down
    change_column :dashboard_metrics, :data, :json
  end
end
