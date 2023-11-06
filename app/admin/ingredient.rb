ActiveAdmin.register Ingredient, as: 'Ingredient' do
  menu false
  config.batch_actions = false
  actions :all, except: :destroy

  permit_params do
    permitted = [:name, :description, :logo, :enable_user_to_filter], :logo, :alt_logo
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
    actions do |ingredient|
      if ingredient.active?
        item('Delete', delete_admin_ingredient_path(ingredient.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_ingredient_path(ingredient.id) , class: [:member_link, :active_btn])
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
      f.input :logo, input_html: {rows: 4}
      f.input :alt_logo, input_html: {rows: 4}
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
      panel "Audit log" do
        render partial: '/active_admin/versions/base_model', locals: {versions: resource.versions.includes(:item)}
      end
    end
  end

  member_action :delete, method: :get do
    ingredient = Ingredient.find(params[:id])
    if ingredient.active?
      ingredient.deleted!
      redirect_to admin_ingredients_path, notice: "Ingredient has been successfully deleted"
    end
  end

  member_action :active, method: :get do
    ingredient = Ingredient.find(params[:id])
    if ingredient.deleted?
      ingredient.active!
      redirect_to admin_ingredients_path, notice: "Ingredient haas been successfully active"
    end
  end

  controller do
    before_action :set_paper_trail_whodunnit
  end

  filter :name
  filter :description
  filter :enable_user_to_filter
end
