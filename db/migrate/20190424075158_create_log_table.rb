class CreateLogTable < ActiveRecord::Migration[5.1]
  def change
    create_table :email_logs do |t|
      t.string  :subject
      t.string  :sender
      t.string  :recipient
      t.datetime  :sent_at
      t.datetime  :failed_at
      t.text :body, :limit => 4294967295
      t.integer :status, default: 0
      t.datetime  :deleted_at, index: true
      t.timestamps
    end
  end
end
