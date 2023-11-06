# ActiveAdmin.register RunningmenuRequest, as: 'Scheduler Requests' do
#   menu false
#   config.batch_actions = false
#   actions :all, :except => [:edit, :update, :destroy, :new]

#   permit_params do
#     permitted = [
#       :runningmenu_request_type,
#       :address_id,
#       :delivery_at,
#       :recurring,
#       :orders,
#       :monday,
#       :tuesday,
#       :wednesday,
#       :thursday,
#       :friday,
#       cuisine_ids: []
#     ]
#   end

#   index do
#     column :id
#     column 'Type' do |r|
#       r.runningmenu_request_type
#     end
#     column 'Company Location' do |r|
#       if r.address.deleted?
#         span do
#           r.address.name
#         end
#         span do
#           status_tag( :deleted )
#         end
#       else
#         r.address.name
#       end
#     end
#     column 'Count' do |r|
#       r.orders
#     end
#     column 'Delivery Date & Time' do |r|
#       r.delivery_at
#     end
#     column :status do |r|
#       if r.active?
#         status_tag( :active )
#       else
#         status_tag( :deleted )
#       end
#     end
#     actions do |runningmenu_request|
#       if runningmenu_request.active?
#         item('Delete', delete_admin_scheduler_request_path(runningmenu_request.id), class: [:member_link, :delete_btn])
#       else
#         item('Activate', active_admin_scheduler_request_path(runningmenu_request.id), class: [:member_link, :active_btn])
#       end
#     end
#   end

#   csv do
#     column :id
#     column 'Type' do |r|
#       r.runningmenu_request_type
#     end
#     column 'Company Location' do |r|
#       r.address.address_line + ' ( ' + r.address.status + ' )'
#     end
#     column 'Delivery Date & Time' do |r|
#       r.delivery_at
#     end
#   end

#   form do |f|
#     f.input :runningmenu_request_type, label: 'Scheduler Request Type'
#     f.input :address, label: 'Company', collection: CompanyAddress.where(status: :active)
#     f.input :delivery_at, label: 'Delivery Date & Time', as: :date_time_picker, input_html: { autocomplete: :off }
#     f.input :recurring, as: :boolean, label: "Recurring"
#     f.input :orders, label: "Recurring"
#     f.input :cuisine_ids, label: 'Cuisines', as: :tags, collection: Cuisine.all
#     div :class => "wrapper_recurring" do
#       f.input :monday, as: :boolean
#       f.input :tuesday, as: :boolean
#       f.input :wednesday, as: :boolean
#       f.input :thursday, as: :boolean
#       f.input :friday, as: :boolean
#     end
#     actions
#   end

#   show do
#     attributes_table do
#       row 'Type' do |r|
#         r.runningmenu_request_type
#       end
#       row 'Company Location' do |r|
#         if r.address.deleted?
#           span do
#             r.address.name
#           end
#           span do
#             status_tag( :deleted )
#           end
#         else
#           r.address.name
#         end
#       end
#       row 'Delivery Date & Time' do |r|
#         r.delivery_at
#       end
#       row 'Cuisines' do |r|
#         raw(r.cuisines.map(&:name).join("<br>"))
#       end
#       row :status do |r|
#         if r.active?
#           status_tag( :active )
#         else
#           status_tag( :deleted )
#         end
#       end
#     end
#   end

#   member_action :delete, method: :get do
#     runningmenu_request = RunningmenuRequest.find(params[:id])
#     if runningmenu_request.active?
#       runningmenu_request.deleted!
#       redirect_to admin_scheduler_requests_path, notice: "Scheduler request has been successfully deleted"
#     end
#   end

#   member_action :active, method: :get do
#     runningmenu_request = RunningmenuRequest.find(params[:id])
#     if runningmenu_request.deleted?
#       runningmenu_request.active!
#       redirect_to admin_scheduler_requests_path, notice: "Scheduler request has been successfully active"
#     end
#   end

#   filter :runningmenu_request_type, label: 'Menu Type', as: :select, collection: -> { RunningmenuRequest.runningmenu_request_types }
#   filter :address, label: 'Company Location', as: :select, collection: CompanyAddress.all
#   filter :delivery_at,label: 'Deleivery Time', as: :date_range
# end
