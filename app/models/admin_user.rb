class AdminUser < User
  default_scope -> { where("user_type IN (?)", [User.user_types[:admin], User.user_types[:developer], User.user_types[:operations]])}
end
