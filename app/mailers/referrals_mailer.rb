class ReferralsMailer < ApplicationMailer
  def send_invite(email, user)
    @invite_email = email
    @user = user
    mail(from: ENV['HELLO_MAIL'], to: @invite_email, subject: "#{@user.name.titleize} Invited You to Use Chowmill: Claim $100 Amazon Gift Card", cc: [ENV['HELLO_MAIL'], user.email])
  end

  def send_vendor_invite(user, vendor_name, vendor_address)
    @user_name = user.name
    @company_name = user.company.name
    @vendor_name = vendor_name
    @vendor_address = vendor_address
    mail(to: ENV['ORDERS_EMAIL'], subject: "#{@user_name}(#{@company_name}) has requested new vendor: #{@vendor_name}")
  end
end
