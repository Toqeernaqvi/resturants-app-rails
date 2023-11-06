class UnsubsidizedUser < User
  default_scope -> {where(user_type: User.user_types[:unsubsidized_user]).where.not(confirmed_at: nil)}

  validates_presence_of :company, :office_admin
  validates_format_of :phone_number,
  :with => /\A[0-9]{3}-[0-9]{3}-[0-9]{4}\Z/,
  :message => "- Phone numbers must be in xxx-xxx-xxxx format.", if: lambda{|u| u.company_admin?}

  def announcements
    Announcement.active.where(users: true)
  end
  
end
