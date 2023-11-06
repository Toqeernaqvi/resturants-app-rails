class RestaurantAdmin < User
  # belongs_to :address
  default_scope -> {where(user_type: User.user_types[:restaurant_admin])}
  validates :phone_number, presence: true, if: lambda {|u| u.primary_contact? }
  validates_format_of :phone_number,
  :with => /\A[0-9]{3}-[0-9]{3}-[0-9]{4}\Z/,
  :message => "- Phone numbers must be in xxx-xxx-xxxx format.", if: lambda {|u| u.primary_contact? }
  validates_format_of :fax,
  :with => /\A[0-9]{3}-[0-9]{3}-[0-9]{4}\Z/,
  :message => "- Fax numbers must be in xxx-xxx-xxxx format.", unless: lambda { |u| u.fax.blank? }

  before_save :fax_number_check, if: lambda {|u| u.fax_changed? || u.fax_summary_check_changed? }
  before_save :phone_number_check, if: lambda {|u| u.phone_number_changed? || u.send_text_reminders_changed? }
  after_save :update_primary_contact, if: lambda {|u| u.saved_change_to_primary_contact? && u.primary_contact? }

  def fax_number_check
    if !self.fax.present?
      self.fax_summary_check = false
    end
  end

  def phone_number_check
    if !self.phone_number.present?
      self.send_text_reminders = false
    end
  end

  def update_primary_contact
    RestaurantAdmin.active.joins(:addresses).where("users.id != ?", self.id).where(primary_contact: true, addresses: { id: self.addresses.pluck(:id)}).update_all(primary_contact: false)
  end

  def announcements
    Announcement.active.where(vendors: true)
  end

end
