class OfficeAdmin < User
  default_scope -> { where(user_type: User.user_types[:admin]) }
end
