module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :current_login_user

    def connect
      params = request.query_parameters()
      if !params.present? && !params["header"].present?
        self.current_user = find_verified_user
      elsif params.present? && params["header"].present?
        self.current_login_user = find_verified_login_user(params)
      end
    end

    private
      def find_verified_user
        admin_user = AdminUser.find_by_id(cookies.signed[:admin_user])
        if admin_user.present?
          admin_user
        else
          reject_unauthorized_connection
        end
      end

      def find_verified_login_user(params)
        auth_params = JSON.parse(params["header"])
        uid = auth_params["uid"].gsub(" ", "+")
        token = auth_params["access-token"]
        client_id = auth_params["client"]
        user = User.find_by_uid(uid)
        if user && user.valid_token?(token, client_id)
          user
        else
          reject_unauthorized_connection
        end
      end
  end
end
