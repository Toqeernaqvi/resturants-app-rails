class BeforePickupWorker
  include Sidekiq::Worker
  sidekiq_options queue: :before_pickup

  def perform(address_runningmenu_id)
    address_runningmenu = AddressesRunningmenu.find address_runningmenu_id
    begin
      puts "Before pickup Job for AddressesRunningmenu: #{ address_runningmenu.id }"
      items = address_runningmenu.runningmenu.orders.active.where(restaurant_address_id: address_runningmenu.address_id).sum(:quantity).to_i
      TwilioSmsService.call(address_runningmenu.runningmenu_id, address_runningmenu.address_id, 'before_pickup') if items > 0
      address_runningmenu.assign_attributes(before_pickup_job_status: AddressesRunningmenu.before_pickup_job_statuses[:processed])      
    rescue StandardError => e
      address_runningmenu.assign_attributes(before_pickup_job_status: AddressesRunningmenu.before_pickup_job_statuses[:not_processed], before_pickup_job_error: e.message)
    end
    address_runningmenu.save(:validate => false)
  end
end