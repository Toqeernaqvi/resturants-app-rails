module PaperTrail
  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern
    after_create :set_latest_version, if: lambda { |v| v.item_type == "Runningmenu" || v.item_type == "Order" }
    after_create :set_restaurant_no_response, if: lambda { |v| v.item_type == "Order" }
  	# after_create :send_latest_version_details_email, if: lambda { |v| v.item_type == "Runningmenu" || v.item_type == "CuisinesMenu" || v.item_type == "Runningmenufield" }

  	def set_latest_version
  		self.item.update_column(:latest_version_id, self.id)
  	end

    def set_restaurant_no_response
      order = self.item
      address_runningmenu = AddressesRunningmenu.find_by(runningmenu_id: order.runningmenu_id, address_id: order.restaurant_address_id)
      address_runningmenu&.update_columns(acknowledge_receipt: :declined, accept_orders: :declined, accept_changes: :declined)
    end

  	# def send_latest_version_details_email
  	# 	 email = ScheduleMailer.schedule_updated_from_frontend(self)
  	# 	 EmailLog.create(sender: 'support@chowmill.com', subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  	# end

  end
end
