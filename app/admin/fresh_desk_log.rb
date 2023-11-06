ActiveAdmin.register FreshDeskLog, as: 'Zen Desk Log' do
  
  menu parent: 'Logs'
  config.batch_actions = false
  actions :all, :except => [:new, :create, :edit, :destroy]

  index do
    column :name
    column :email
    column :subject
    column "Description" do |freshdesklog|
      freshdesklog.description.truncate(70, omission: ' ...').html_safe rescue nil
    end
    column "Attachments" do |freshdesklog|
      freshdesklog.attachment.html_safe rescue nil
    end
    column :widget_type
    column "Created at" do |freshdesklog|
      freshdesklog.created_at.strftime("%m/%d/%Y")
    end
    actions
  end

  show do
    attributes_table do
      row :name
      row :email
      row :subject
      row "Description" do |freshdesklog|
        freshdesklog.description&.html_safe
      end
      row "Attachments" do |freshdesklog|
        freshdesklog.attachment&.html_safe
      end
      row :widget_type
    end
  end

  filter :name
  filter :email
  filter :subject
  filter :widget_type, as: :select, collection: -> {FreshDeskLog.widget_types}
  
end