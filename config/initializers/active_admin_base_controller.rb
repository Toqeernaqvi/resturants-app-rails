class ActiveAdmin::BaseController
  def user_for_paper_trail
    current_admin_user.try(:name)
  end
end