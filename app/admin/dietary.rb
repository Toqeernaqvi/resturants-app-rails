ActiveAdmin.register Dietary, as: 'Dietary' do
  menu false
  config.batch_actions = false
  actions :all, except: :destroy

  permit_params do
    permitted = [:name, :description, :enable_user_to_filter, :logo, :alt_logo]
  end

  index do
    column :id
    column :name
    column :description
    column :enable_user_to_filter
    column 'Logo' do |d|
      d.logo&.html_safe
    end
    column 'Alt Logo' do |d|
      d.alt_logo&.html_safe
    end
    actions do |dietary|
      if dietary.active?
        item('Delete', delete_admin_dietary_path(dietary.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_dietary_path(dietary.id) , class: [:member_link, :active_btn])
      end
    end
  end

  csv do
    column :id
    column :name
    column :description
    column :enable_user_to_filter
    column 'Logo' do |d|
      d.logo&.html_safe
    end
    column 'Alt Logo' do |d|
      d.alt_logo&.html_safe
    end
  end

  form do |f|
    f.inputs do
      f.input :enable_user_to_filter
      f.input :name
      f.input :description, input_html: {rows: 4}
      f.input :logo, as: :text, input_html: {rows: 4}
      f.input :alt_logo, as: :text, input_html: {rows: 4}
    end
    f.actions do
      f.action(:submit)
      f.cancel_link
    end
  end

  show do
    attributes_table do
      row :name
      row :description
      row :enable_user_to_filter
      row 'Logo' do |d|
        d.logo&.html_safe
      end
      row 'Alt Logo' do |d|
        d.alt_logo&.html_safe
      end
    end
  end

  member_action :delete, method: :get do
    dietary = Dietary.find(params[:id])
    if dietary.active?
      dietary.deleted!
      redirect_to admin_dietaries_path, notice: "Dietary has been successfully deleted"
    end
  end

  member_action :active, method: :get do
    dietary = Dietary.find(params[:id])
    if dietary.deleted?
      dietary.active!
      redirect_to admin_dietaries_path, notice: "Dietary haas been successfully active"
    end
  end

  filter :name
  filter :description
  filter :enable_user_to_filter
end
