class CompanyMailer < ApplicationMailer

  def child_created(child)
    @child = child
    @company_admin = child.users.where(:user_type=>User.user_types["company_admin"]).last
    @company_address = child.addresses.last
    @header = "New Child Company Created: #{child.name}"
    mail(to: ENV['ORDERS_EMAIL'], subject: @header)
  end

  def confirm_user_access(admin, user, invite_sent)
    @admin = admin
    @user = user
    @invite_sent = invite_sent
    subject_part = @invite_sent ? "has been granted access to Chowmill" : "Requested Chowmill Access"
    subject = [user.first_name.capitalize, user.last_name.capitalize, subject_part].join(" ")
    mail(to: admin.email, subject: subject)
  end

  def user_access(user)
    @user = user
    subject = "#{user.first_name.capitalize} #{user.last_name.capitalize} Requested Chowmill Access"
    mail(to: ENV['RECIPIENT_EMAIL'], subject: subject)
  end


  def user_invitation_error(user, errors)
    @user = user
    @errors = errors
    subject = "#{user.first_name.capitalize} #{user.last_name.capitalize} Error in Request of Chowmill Access"
    mail(to: ENV['RECIPIENT_EMAIL'], subject: subject)
  end

end
