ActiveAdmin.register Cuisine, as: 'Cuisine' do
  menu false
  config.batch_actions = false
  actions :all, except: :destroy

  permit_params do
    permitted = [:name, :description]
  end

  index do
    column :id
    column :name
    column :description
    actions do |cuisine|
      if cuisine.active?
        item('Delete', delete_admin_cuisine_path(cuisine.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_cuisine_path(cuisine.id) , class: [:member_link, :active_btn])
      end
    end
  end
  csv do
    column :id
    column :name
    column :description
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :description
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
      panel "Audit log" do
        render partial: '/active_admin/versions/base_model', locals: {versions: resource.versions.includes(:item)}
      end
    end
  end

  member_action :delete, method: :get do
    cuisine = Cuisine.find(params[:id])
    if cuisine.active?
      cuisine.deleted!
      redirect_to admin_cuisines_path, notice: "Cuisine has been successfully deleted"
    end
  end

  member_action :active, method: :get do
    cuisine = Cuisine.find(params[:id])
    if cuisine.deleted?
      cuisine.active!
      redirect_to admin_cuisines_path, notice: "Cuisine haas been successfully active"
    end
  end

  controller do
    before_action :set_paper_trail_whodunnit
  end

  filter :name
  filter :description
end
