class Addreportstabletodb < ActiveRecord::Migration[5.1]
  def change
    create_table :reports do |t|
      t.string :name
      t.integer :report_type
      t.integer :scheduled_period
      t.integer :scheduled_time
      t.boolean :enable_error_logging, default: false
    end

    create_join_table :reports, :users do |t|
      t.index [:report_id, :user_id]
    end
  end
end
