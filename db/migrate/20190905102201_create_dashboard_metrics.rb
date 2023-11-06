class CreateDashboardMetrics < ActiveRecord::Migration[5.1]
  def change
    create_table :dashboard_metrics do |t|
      t.integer :metric_type
      t.json :data
      t.timestamps
    end
  end
end
