class CompanyAdmin < User
  default_scope -> {where(user_type: User.user_types[:company_admin]).where.not(confirmed_at: nil)}
  # validates :desk_phone, presence: true
  #validates_presence_of :company
  #validates :company_id, presence: true
  validates_format_of :phone_number,
  :with => /\A[0-9]{3}-[0-9]{3}-[0-9]{4}\Z/,
  :message => "- Phone numbers must be in xxx-xxx-xxxx format.", if: lambda{|u| u.company_admin? }
  # validates_length_of :phone_number, in: 7..15
  # validates_format_of :phone_number, :with => /^[+-]?[0-9]+$/ , :message => "must be number including - or +", :multiline => true

  def announcements
    Announcement.active.where(admins: true)
  end
end
