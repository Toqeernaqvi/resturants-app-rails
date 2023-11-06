ActiveAdmin.register QuickbookLog, as: 'Quickbook Log' do

  menu parent: 'Logs'
  config.batch_actions = false
  actions :all, :except => [:new, :create, :destroy ]

  index do
    column :upload_identity
    column :upload_type
    column :event_type
    column :quickbook_identity
    column :created_at
  end

  filter :upload_identity
  filter :upload_type, as: :select, collection: -> {QuickbookLog.upload_types}
  filter :event_type, as: :select, collection: -> {QuickbookLog.event_types}
  filter :quickbook_identity
  filter :created_at, as: :date_range

end