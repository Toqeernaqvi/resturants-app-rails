ActiveAdmin.register Setting do
  menu parent: 'Settings'
  config.batch_actions = false
  actions :show, :index, :edit, :update

  permit_params do
    permitted = [:minimum_amount, :distance_radius, :drive_radius, :breakfast, :lunch, :dinner, :display_nutritionix, :display_intercom]
  end

  form do |f|
    f.inputs do
      f.input :minimum_amount
      f.input :distance_radius
      f.input :drive_radius
      f.input :breakfast
      f.input :lunch
      f.input :dinner
      f.input :display_nutritionix
      f.input :display_intercom
    end
    f.actions do
      f.action(:submit)
      f.cancel_link
    end
  end

  index do
    column :id
    column :minimum_amount
    column :distance_radius
    column :drive_radius
    column :breakfast
    column :lunch
    column :dinner
    column :display_nutritionix
    column :display_intercom
    actions do |setting|
      item('Authorize Quickbook', login_admin_settings_path, target: "_blank", class: :member_link) if setting.token_expires_at < Time.current
    end
  end

  collection_action :login, method: :get do
    redirect_uri = ENV['BACKEND_HOST']+"/admin/quickbooks_oauth/webhook"
    # redirect_uri = "http://94a1de3f6dbd.ngrok.io/admin/quickbooks_oauth/webhook"
    grant_url = $oauth2_client.auth_code.authorize_url(redirect_uri: redirect_uri, response_type: "code", state: SecureRandom.hex(12), scope: "com.intuit.quickbooks.accounting")
    redirect_to grant_url
  end

  csv do
    column :id
    column :minimum_amount
    column :distance_radius
    column :drive_radius
    column :breakfast
    column :lunch
    column :dinner
    column :display_nutritionix
    column :display_intercom
  end

  show do
    attributes_table do
      row :id
      row :minimum_amount
      row :distance_radius
      row :drive_radius
      row :breakfast
      row :lunch
      row :dinner
      row :display_nutritionix
      row :display_intercom
      panel "Audit log" do
        render partial: '/active_admin/versions/base_model', locals: {versions: resource.versions.includes(:item)}
      end
    end
  end

  controller do
    before_action :set_paper_trail_whodunnit
  end

  filter :minimum_amount, label: "Minimum Amount"
  filter :distance_radius, label: "Distance Radius"
  filter :drive_radius, label: "Drive Radius"
  filter :breakfast
  filter :lunch
  filter :dinner
end
