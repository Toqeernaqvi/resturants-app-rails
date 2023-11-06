ActiveAdmin.register User, as: 'AdminRole' do
  menu false
  config.batch_actions = false
  actions :edit, :update
  breadcrumb do
    if request.params[:action] == "new"
      [link_to('Admin', admin_users_path)]
    end
  end

  permit_params do
    permitted = []
    permitted.push :password if params[:user] && !params[:user][:password].blank?
  end

  form do |f|
    f.inputs do
      f.input :password, label: "Reset Password"
    end
    f.actions do
      f.action :submit
      f.cancel_link admin_users_path
    end
  end
  controller do
    def update
      admin_user = AdminUser.find params["id"]
      if params[:user][:password].blank?
        redirect_to edit_admin_admin_role_path(id: admin_user.id), alert: "can't be blank"
      else
        if admin_user.update(permitted_params[:user])
          redirect_to admin_users_path
        else
          redirect_to edit_admin_admin_role_path(id: admin_user.id), alert: admin_user.errors.full_messages[0]
        end
      end
    end
  end

end