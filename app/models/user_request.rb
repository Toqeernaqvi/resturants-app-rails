class UserRequest < ApplicationRecord
  belongs_to :company, optional: true
  validates :first_name, :last_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates_uniqueness_of :email

  attr_accessor :invited_user

  after_create :find_inform_company_admins

  def find_inform_company_admins
    query = email.split("@")[1]
    admins = CompanyAdmin.active.where("allow_admin_to_manage_users = ? AND email ILIKE ?", true, "%#{query}%")
    if admins.pluck(:company_id).uniq.length == 1
      self.update_columns(company_id: admins.pluck(:company_id).uniq.last)
      admins.each do |admin|
        if admin.company.allow_users_to_onboard_without_admin_approval
          if self.invite_user(admin.id)
            self.invited_user = true
            email = CompanyMailer.confirm_user_access(admin, self, true)
          end
        else
          email = CompanyMailer.confirm_user_access(admin, self, false)
        end
        EmailLog.create(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source)) if email.present?
      end
    else
      email = CompanyMailer.user_access(self)
      EmailLog.create(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
    end
  end

  def invite_user(admin_id)
    company_user = self.company.company_users.new(
      first_name: self.first_name,
      last_name: self.last_name,
      email: self.email,
      survey_mail: true,
      cutoff_hour_breakfast_reminder: true,
      cutoff_hour_lunch_reminder: true,
      cutoff_hour_dinner_reminder: true,
      cutoff_day_breakfast_reminder: true,
      cutoff_day_lunch_reminder: true,
      cutoff_day_dinner_reminder: true,
      time_zone: self.company.time_zone,
      office_admin_id: admin_id
    )
    if company_user.save
      return true
    else
      email = CompanyMailer.user_invitation_error(company_user, company_user.errors.full_messages)
      EmailLog.create(sender: email.from.first, subject: email.subject, cc: email.cc&.join(', '), recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      return false
    end
  end
end
