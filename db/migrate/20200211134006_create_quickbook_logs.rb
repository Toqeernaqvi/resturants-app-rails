class CreateQuickbookLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :quickbook_logs do |t|
      t.integer :upload_identity
      t.integer :upload_type
      t.integer :event_type
      t.integer :quickbook_identity

      t.timestamps
    end
  end
end
