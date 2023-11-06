class CreateFreshDeskLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :fresh_desk_logs do |t|
      t.integer :ticketidentity
      t.integer :widget_type
      t.string :name
      t.string :portal_name
      t.string :requester
      t.string :email
      t.string :subject
      t.text :description
      t.text :attachment
      t.string :ticket_url

      t.timestamps
    end
  end
end
