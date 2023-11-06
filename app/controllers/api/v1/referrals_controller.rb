# app/controllers/api/v1/referrals_controller.rb
class Api::V1::ReferralsController < Api::V1::ApiController

  #POST referrals/send_invite
  def invite_referred
    if params[:emails].present?
      emails = params[:emails].split(/[,\s<>]+/)
      emails = emails.select{|a| a.match?URI::MailTo::EMAIL_REGEXP }
      if emails.blank?
        error(E_INTERNAL, 'Emails could not be parsed correctly')
      else
        emails.each do |data|
          email = ReferralsMailer.send_invite(data, current_member)
          EmailLog.create(sender: ENV['HELLO_MAIL'], subject: email.subject, recipient: email.to.first, cc: email.cc&.join(', '), body: Base64.encode64(email.body.raw_source))
        end
        render json: {message: 'Invited successfully.'}
      end
    else
      render json: {message: 'Emails can\'t be blank.'}
    end
  end
end
