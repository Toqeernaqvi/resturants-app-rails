ActiveAdmin.register Announcement do
  menu parent: 'Settings'
  actions :all, except: :destroy

  permit_params do
    permitted = [:title, :description, :expiration, :admins, :users, :vendors]
  end

  index do
    column :id
    column :title
    column :description do |a|
      a.description.html_safe
    end
    column :expiration
    column :admins
    column :users
    column :vendors
    actions do |announcement|
      if announcement.active?
        item('Delete', delete_admin_announcement_path(announcement.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_announcement_path(announcement.id) , class: [:member_link, :active_btn])
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :title
      f.input :description, as: :ckeditor
      f.input :expiration, as: :date_time_picker, picker_options: { min_date: Time.current.strftime('%Y-%m-%d %H:%M') }, input_html: { autocomplete: :off }
    end
    f.inputs "Audience" do
      f.input :admins
      f.input :users
      f.input :vendors
    end
    f.actions
  end

  show do
    attributes_table do
      row :title
      row "Description" do |a|
        a.description.html_safe
      end
      row :expiration
      row :admins
      row :users
      row :vendors
      row :created_at
      row :updated_at
    end
  end

  member_action :delete, method: :get do
    announcement = Announcement.find(params[:id])
    if announcement.active?
      announcement.deleted!
      redirect_to admin_announcements_path, notice: "Announcement has been successfully deleted"
    end
  end

  member_action :active, method: :get do
    announcement = Announcement.find(params[:id])
    if announcement.deleted?
      announcement.active!
      redirect_to admin_announcements_path, notice: "Announcement haas been successfully active"
    end
  end

  filter :title
  filter :description
  filter :expiration
  filter :admins
  filter :users
  filter :vendors

end
