# class OnfleetTaskJob < ApplicationJob
#   queue_as :onfleet_task

#   def perform(runningmenu_ids, create_type)
  	
#   	if create_type
#   		addresses_collec = []
# 	    Runningmenu.where(id: runningmenu_ids.split(",")).each do |runningmenu|
# 	      puts "OnFleet: in a loop runningmenu_id #{runningmenu.id}"
# 	      if runningmenu.user.present? && !runningmenu.user.admin?
# 	        admin = runningmenu.user
# 	      else
# 	        admin = runningmenu.company.company_admins.active.where.not('desk_phone = ?', "").first
# 	      end

# 	      if admin.present?
# 	        ph_no = (admin.sms_notification? && admin.phone_number.present?) ? admin.phone_number : admin.desk_phone
# 	        skip_notification = !admin.sms_notification
# 	      end

# 	      appartment_no = runningmenu.address.suite_no.present? ? (runningmenu.address.suite_no + " ") : ""
# 	      pickup_task, pickup_task_per_restaurant, dropoff_task = nil
# 	      beverages_orders = runningmenu.orders.joins(:fooditem).active.where(restaurant_address_id: Restaurant.find_by_name(ENV['BEV_AND_MORE']).addresses.pluck(:id)).select('fooditems.name AS fooditem_name, SUM(orders.quantity) AS quantity').group('fooditems.name')
# 	      b_orders = ""
# 	      beverages_orders.each do |bo|
# 	        b_orders += "\n#{bo.quantity} #{bo.fooditem_name}"
# 	      end
# 	      pickup_note = "pickup labels and utensils at chowmill.#{b_orders}"
# 	      driver = (runningmenu.driver.present? && runningmenu.driver.worker_id.present?) ? runningmenu.driver : ""
# 	      if runningmenu.orders.active.present? && beverages_orders.present?
# 	        begin
# 	          addr = Address.where(latitude: '37.4035753199216', longitude: '-121.904924149765')
# 	          pickup_task = Onfleet::Task.create(
# 	            destination: {
# 	              address: {
# 	                unparsed: '2345 Harris Way, San Jose, CA 95133' #address.formatted
# 	              },
# 	            },
# 	            recipients: [],
# 	            pickup_task: true,
# 	            complete_before: runningmenu.delivery? ? (runningmenu.delivery_at_timezone.to_f * 1000).to_i : ((runningmenu.delivery_at_timezone - 60.minutes).to_f * 1000).to_i,
# 	            complete_after: runningmenu.delivery? ? (runningmenu.delivery_at_timezone.to_f * 1000).to_i : ((runningmenu.delivery_at_timezone - 70.minutes).to_f * 1000).to_i,
# 	            notes: "Meeting Name: #{runningmenu.runningmenu_name}, Order Number: #{runningmenu.id}, "+pickup_note,
# 	            quantity: beverages_orders.sum(&:quantity),
# 	            service_time: 10,
# 	          )
# 	          if pickup_task.present?
# 	            if driver.present?
# 	              Onfleet::Task.update(pickup_task.id, {worker: driver.worker_id})
# 	            end
# 	            if addr.present?
# 	              addr.each do |a|
# 	                addresses_collec.push( a.id)
# 	              end
# 	            end
# 	            runningmenu.update_column(:pickup_task_id, pickup_task.id)
# 	            puts "OnFleet: Task created for pickup"
# 	          else
# 	            puts "OnFleet: Task failed to for pickup"
# 	          end
# 	        rescue StandardError => e
# 	          subject = "OnFleet: Pickup Task failed for Scheduler #{runningmenu.id}"
# 	          email = ScheduleMailer.onfleet_task_failed(runningmenu, subject, e.message)
# 	          EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
# 	          puts " OnFleet: #{e.message}"
# 	        end
# 	      end

# 	      runningmenu.addresses.where.not(addressable_id: Restaurant.find_by_name(ENV['BEV_AND_MORE']).id).each do |address|
# 	        if runningmenu.orders.active.where(restaurant_address_id: address.id).present?
# 	          begin
# 	            dependency = []
# 	            if pickup_task.present?
# 	              dependency.push(pickup_task.id)
# 	            end
# 	            unless addresses_collec.include?(address.id)
# 	              pickup_task_per_restaurant = Onfleet::Task.create(
# 	                destination: {
# 	                  address: {
# 	                    name: address.name,
# 	                    unparsed: (address.suite_no.present? ? (address.suite_no + " ") : "") + address.address_line
# 	                  },
# 	                },
# 	                recipients: [],
# 	                dependencies: dependency,
# 	                pickup_task: true,
# 	                complete_before: runningmenu.delivery? ? (runningmenu.delivery_at_timezone.to_f * 1000).to_i : ((runningmenu.delivery_at_timezone - 45.minutes).to_f * 1000).to_i,
# 	                complete_after: runningmenu.delivery? ? (runningmenu.delivery_at_timezone.to_f * 1000).to_i : ((runningmenu.delivery_at_timezone - 60.minutes).to_f * 1000).to_i,
# 	                notes: ("Meeting Name: #{runningmenu.runningmenu_name}, Order Number: #{runningmenu.id}, "+"Pickup utensils & do inventory of meals."),
# 	                quantity: runningmenu.orders.present? ? runningmenu.orders.active.where(restaurant_address_id: address.id).sum(:quantity) : 0,
# 	              )
# 	              if pickup_task_per_restaurant.present?
# 	                if driver.present?
# 	                  Onfleet::Task.update(pickup_task_per_restaurant.id, {worker: driver.worker_id})
# 	                end
# 	                address_runningmenu = AddressesRunningmenu.find_by(address_id: address.id, runningmenu_id: runningmenu.id)
# 	                address_runningmenu.update_columns(restaurant_task_id: pickup_task_per_restaurant.id, task_status: :created)
# 	                puts "OnFleet: Task created for restaurant #{address.name}"
# 	              else
# 	                puts "OnFleet: Task failed to create for restaurant #{address.name}"
# 	              end
# 	            end
# 	          rescue StandardError => e
# 	            subject = "OnFleet: Pickup Task failed for Scheduler #{runningmenu.id} and address #{address.name}"
# 	            email = ScheduleMailer.onfleet_task_failed(runningmenu, subject, e.message)
# 	            EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
# 	            puts " OnFleet: #{e.message}"
# 	          end
# 	        end
# 	      end

# 	      if runningmenu.orders.active.present?
# 	        begin
# 	          dependency = []
# 	          if pickup_task_per_restaurant.present? && pickup_task.present?
# 	            dependency.push(pickup_task_per_restaurant.id, pickup_task.id)
# 	          elsif pickup_task.present?
# 	            dependency.push(pickup_task.id)
# 	          elsif pickup_task_per_restaurant.present?
# 	            dependency.push(pickup_task_per_restaurant.id)
# 	          end
# 	          if admin.present?
# 	            dropoff_task = Onfleet::Task.create(
# 	              destination: {
# 	                address: {
# 	                  name: runningmenu.address.name,
# 	                  unparsed: appartment_no + runningmenu.address.address_line
# 	                },
# 	                notes:  "#{runningmenu.delivery_instructions.blank? ?  '' : "Delivery Instructions: #{runningmenu.delivery_instructions}." }"
# 	              },
# 	              recipients: [{
# 	                name: admin.name,
# 	                phone: ph_no,
# 	              }],
# 	              dependencies: dependency,
# 	              pickup_task: false,
# 	              complete_before: ((runningmenu.delivery_at_timezone).to_f * 1000).to_i,
# 	              complete_after: runningmenu.delivery? ? ((runningmenu.delivery_at_timezone).to_f * 1000).to_i : ((runningmenu.delivery_at_timezone - 15.minutes).to_f * 1000).to_i,
# 	              notes:  "Meeting Name: #{runningmenu.runningmenu_name}, Order Number: #{runningmenu.id}",
# 	              quantity: runningmenu.orders.exists? ? runningmenu.orders.active.sum(:quantity) : 0,
# 	              requirements: {
# 	                photo: true
# 	              },
# 	            )
# 	          else
# 	            subject = "OnFleet: Dropoff Task failed for Scheduler #{runningmenu.id}"
# 	            email = ScheduleMailer.onfleet_task_failed(runningmenu, subject, "Can't find any company admin for #{runningmenu.company.name} as recipient.")
# 	            EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
# 	          end
# 	          if dropoff_task.present?
# 	            if driver.present?
# 	              Onfleet::Task.update(dropoff_task.id, {worker: driver.worker_id})
# 	            end
# 	            runningmenu.update_columns(task_id: dropoff_task.id, task_status: :created)
# 	            HTTParty.put("https://onfleet.com/api/v2/recipients/#{dropoff_task.recipients.first.id}", :body => {:skipSMSNotifications=> skip_notification}.to_json, :basic_auth => {:username=>"#{ENV['ONFLEET_API_KEY']}"})
# 	            puts "OnFleet: Dropoff Task Created"
# 	          else
# 	            puts "OnFleet: Dropoff Task Failed to create"
# 	          end
# 	        rescue StandardError => e
# 	          subject = "OnFleet: Dropoff Task failed for Scheduler #{runningmenu.id}"
# 	          email = ScheduleMailer.onfleet_task_failed(runningmenu, subject, e.message)
# 	          EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
# 	          puts " OnFleet: #{e.message}"
# 	        end
# 	      end
# 	    end
#   	else
#   		# Update Type
#   		runningmenu = runningmenu_ids
#   		pickup_task = nil
#       beverages_orders = runningmenu.orders.joins(:fooditem).active.where(restaurant_address_id: Restaurant.find_by_name(ENV['BEV_AND_MORE']).addresses.pluck(:id)).select('fooditems.name AS fooditem_name, SUM(orders.quantity) AS quantity').group('fooditems.name')
#       b_orders = ""
#       restaurant_task_ids  = runningmenu.addresses_runningmenus.where.not(restaurant_task_id: nil).pluck(:restaurant_task_id)
#       dependency = []
#       if restaurant_task_ids.present? && runningmenu.task_id.present?
#         dependency.push(restaurant_task_ids, runningmenu.task_id)
#       elsif restaurant_task_ids.present? && !runningmenu.task_id.present?
#         dependency.push(restaurant_task_ids)
#       elsif runningmenu.task_id.present?
#         dependency.push(runningmenu.task_id)
#       end
#       beverages_orders.each do |bo|
#         b_orders += "\n#{bo.quantity} #{bo.fooditem_name}"
#       end
#       if runningmenu.pickup_task_id.present?
#         task = Onfleet::Task.get(runningmenu.pickup_task_id)
#         quantity = beverages_orders.sum(&:quantity)
#         if quantity != task.quantity
#           task.quantity = quantity
#           task.save
#         end
#       elsif beverages_orders.present? && !runningmenu.pickup_task_id.present?
#         begin
#           pickup_task = Onfleet::Task.create(
#             destination: {
#               address: {
#                 unparsed: '2345 Harris Way, San Jose, CA 95133' #address.formatted
#               },
#             },
#             recipients: [],
#             pickup_task: true,
#             dependencies: dependency.flatten,
#             complete_before: runningmenu.delivery? ? (runningmenu.delivery_at_timezone.to_f * 1000).to_i : ((runningmenu.delivery_at_timezone - 60.minutes).to_f * 1000).to_i,
#             complete_after: runningmenu.delivery? ? (runningmenu.delivery_at_timezone.to_f * 1000).to_i : ((runningmenu.delivery_at_timezone - 70.minutes).to_f * 1000).to_i,
#             notes: "Pickup new labels for changed orders.#{b_orders}",
#             quantity: beverages_orders.sum(&:quantity),
#             service_time: 10,
#           )
#           if pickup_task.present?
#             if runningmenu.driver.present? && runningmenu.driver.worker_id.present?
#               Onfleet::Task.update(pickup_task.id, {worker: runningmenu.driver.worker_id})
#             end
#             runningmenu.update_column(:pickup_task_id, pickup_task.id)
#             puts "OnFleet: Task created for pickup"
#           else
#             puts "OnFleet: Task failed to for pickup"
#           end
#         rescue StandardError => e
#           subject = "OnFleet: Pickup Task failed for Scheduler #{runningmenu.id}"
#           email = ScheduleMailer.onfleet_task_failed(runningmenu, subject, e.message)
#           EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
#           puts " OnFleet: #{e.message}"
#         end
#       end
#       if runningmenu.task_id.present?
#         task = Onfleet::Task.get(runningmenu.task_id)
#         quantity = runningmenu.orders.active.sum(:quantity)
#         if quantity != task.quantity
#           task.quantity = quantity
#           task.save
#         end
#       end
#       runningmenu.addresses.active.each do |address|
#         address_runningmenu = AddressesRunningmenu.find_by(address_id: address.id, runningmenu_id: runningmenu.id)
#         if address_runningmenu.restaurant_task_id.present?
#           task = Onfleet::Task.get(address_runningmenu.restaurant_task_id)
#           quantity = runningmenu.orders.active.where(restaurant_address_id: address.id).sum(:quantity)
#           if quantity != task.quantity
#             task.quantity = quantity
#             task.save
#           end
#         end
#       end

#   	end

#   end
# end
