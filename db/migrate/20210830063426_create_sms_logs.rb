class CreateSmsLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :sms_logs do |t|
      t.string :from
      t.string :to
      t.text :body
      t.integer :status, default: 0
      t.string :failed_reason
      t.timestamps
    end
  end
end
