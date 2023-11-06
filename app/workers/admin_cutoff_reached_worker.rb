class AdminCutoffReachedWorker
  include Sidekiq::Worker
  sidekiq_options queue: :admin_cutoff_reached_queue

  def perform(runningmenu_id)
    runningmenu = Runningmenu.approved.find_by_id runningmenu_id
    if runningmenu.present?
      begin
        puts "Changes Email At Admin Cutoff start for scheduler #{runningmenu.id} - #{Time.current}"
        runningmenu.set_before_pickup_job
        orders = Order.find_by_sql("select * from order_at_admin_cutoff(#{runningmenu.id})")
        unless orders.blank?
          email = OrderMailer.orders_diff_at_admin_cuttof(runningmenu, orders)
          EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        end
        Order.assign_groups_to_orders_after_cutoff(runningmenu) if runningmenu.company.enable_grouping_orders && (runningmenu.cutoff_at != runningmenu.admin_cutoff_at)
        runningmenu.addresses.active.each do |address|
          puts "Admin Cutoff start for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
          OrdersDetailToRestaurantAtAdminCutoffJob.perform_later(runningmenu, address)
        end
        runningmenu.assign_attributes(admin_cutoff_reached_job_status: Runningmenu.admin_cutoff_reached_job_statuses[:processed], skip_set_dates: true, skip_set_jobs: true)
        runningmenu.generate_invoice_job if runningmenu.delivery? && !runningmenu.enqueued_for_invoice
        puts "Admin cutoff processing end for scheduler #{runningmenu.id} - #{Time.current}"
      rescue StandardError => e
        runningmenu.assign_attributes(admin_cutoff_reached_job_status: Runningmenu.admin_cutoff_reached_job_statuses[:not_processed], admin_cutoff_reached_job_error: e.message, skip_set_dates: true, skip_set_jobs: true)
      end
      runningmenu.save(validate: false)
    end
  end
  
end