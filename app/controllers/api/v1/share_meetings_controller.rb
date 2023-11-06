class Api::V1::ShareMeetingsController < Api::V1::ApiController
  skip_before_action :authenticate_active_user, only: [:add_customer, :by_token]
  before_action :set_meeting, except: [:add_customer]
  before_action :check_member, only: [:create]
  before_action :set_share_meeting, only: [:resend_invite, :add_customer]

  def create
    share_meeting = @meeting.share_meetings.new(meeting_params.merge(user_id: current_member.id))
    if share_meeting.valid?
      emails = ShareMeeting.parse_emails(meeting_params[:emails])
      if emails.blank?
        error(E_INTERNAL, 'Emails could not be parsed correctly')
      else
        failed_emails = []
        emails.each do |email|
          meeting = @meeting.share_meetings.create(meeting_params.merge(user_id: current_member.id, email: email))
          unless meeting.valid?
            failed_emails << {email: email, message: meeting.errors.full_messages[0] }
          end
        end
        render json: {failed_emails: failed_emails}
      end
    else
      error(E_INTERNAL, share_meeting.errors.full_messages[0])
    end
  end

  def by_token
    if @meeting.present?
      share_meeting = @meeting.share_meetings.find_by(email: meeting_params[:email])
      if share_meeting.present?
        share_meeting.update(meeting_params)
      else
        share_meeting = @meeting.share_meetings.new(meeting_params.merge(user_id: @meeting.user_id))
        unless share_meeting.save
          error(E_INTERNAL, share_meeting.errors.full_messages[0])
          return
        end
      end
      render json: {share_meeting_link: "#{ENV['FRONTEND_HOST']}/share-meeting/#{@meeting.delivery_at.strftime('%m-%d-%Y')}/#{share_meeting.token}"}
    else
      error(E_INTERNAL, 'Invalid token')
    end
  end

  def resend_invite
    email = ScheduleMailer.share(@share_meeting)
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
    render json: { message: 'User is invited successfully!' }
  end

  def add_customer
    if params[:token].present? && params[:nonce].present?
      if @share_meeting.update(nonce: params[:nonce])
        render '/api/v1/companies/index'
      else
        error(E_INTERNAL, @share_meeting.errors.full_messages[0])
      end
    end
  end

  #POST /share_meetings/generate_token
  def generate_token
    if !@meeting.share_token.present?
      token = SecureRandom.urlsafe_base64
      @meeting.update_column(:share_token, token)
    else
      token = @meeting.share_token
    end
    render json: { share_token: "#{token}" }
  end

	private

  def set_meeting
    if params[:share_token].present?
      @meeting = Runningmenu.find_by(slug: params[:schedule_id], share_token: params[:share_token])
    else
      @meeting = Runningmenu.friendly.find params[:schedule_id]
    end
  end

  def check_member
    if current_member.company_user? || current_member.unsubsidized_user?
      error(401, 'Company Users are not allowed')
    end
  end

  def set_share_meeting
    if params[:share_meeting_id].present?
      @share_meeting = @meeting.share_meetings.find params[:share_meeting_id]
    else
      @share_meeting = ShareMeeting.find_by_token(params[:token])
    end
  end

  def meeting_params
    params.require(:share_meeting).permit(:user_id, :runningmenu_id, :emails, :email, :first_name, :last_name)
  end
end
