class Contact < ApplicationRecord
  #acts_as_paranoid

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  belongs_to :address
  validates_format_of :phone_number,
  :with => /\A[0-9]{3}-[0-9]{3}-[0-9]{4}\Z/,
  :message => "- Phone numbers must be in xxx-xxx-xxxx format.", unless: lambda { |a| a.phone_number.blank? }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates_uniqueness_of :email, scope: :address
  validates :name, presence: true
  validates_format_of :fax,
  :with => /\A[0-9]{3}-[0-9]{3}-[0-9]{4}\Z/,
  :message => "- Fax numbers must be in xxx-xxx-xxxx format.", unless: lambda { |a| a.fax.blank? }
  before_save :fax_number_check, if: lambda {|a| a.fax_changed? || a.fax_summary_check_changed?}
  before_save :phone_number_check, if: lambda {|a| a.phone_number_changed? || a.send_text_reminders_changed?}

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

end
