# # app/controllers/api/v1/schedule_requests_controller.rb
# class Api::V1::ScheduleRequestsController < Api::V1::ApiController
#   devise_token_auth_group :member, contains: [:company_admin, :company_user]
#   before_action :set_runningmenurequest, only: [:update]

#   # POST /schedule_requests/:id/orders
#   def create
#     runningmenu_request = RunningmenuRequest.new(request_params.merge(user_id: current_member.id))
#     if runningmenu_request.save
#       email = ScheduleRequestMailer.schedule_request_placed(runningmenu_request)
#       EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
#       render json: {message: 'Scheduler request created successfully'}
#     else
#       error(E_INTERNAL, runningmenu_request.errors.full_messages[0])
#     end
#   end

#   #PUT /schedule_requests/:id
#   def update
#     if @runningmenu_request.update(request_params)
#       if @runningmenu_request.runningmenus.present?
#         runningmenu = @runningmenu_request.runningmenus.last
#         runningmenu.menu_type = @runningmenu_request.menu_type
#         runningmenu.orders_count = @runningmenu_request.orders
#         runningmenu.special_request = @runningmenu_request.special_request
#         runningmenu.menu_type = @runningmenu_request.menu_type
#         runningmenu.cuisines_menus.destroy_all
#         runningmenu.cuisines << @runningmenu_request.cuisines
#         runningmenu.save!
#       end
#       render json: {message: 'Scheduler request updated successfully'}
#     else
#       error(E_INTERNAL, @runningmenu_request.errors.full_messages[0])
#     end
#   end

#   private
#   def request_params
#     params.require(:request).permit(
#       :runningmenu_request_type,
#       :address_id,
#       :delivery_at,
#       :end_time,
#       :recurring,
#       :orders,
#       :monday,
#       :tuesday,
#       :wednesday,
#       :thursday,
#       :friday,
#       :menu_type,
#       :special_request,
#       :schedular_check,
#       cuisines_requests_attributes: [
#         :id,
#         :_destroy,
#         :cuisine_id
#       ],
#       runningmenurequestfields_attributes: [
#         :id,
#         :_destroy,
#         :field_id,
#         :fieldoption_id,
#         :value
#       ],
#     )
#   end

#    def set_runningmenurequest
#     @runningmenu_request = RunningmenuRequest.find params[:id]
#   end
# end
