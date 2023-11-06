class InvoiceWorker
  include Sidekiq::Worker
  sidekiq_options queue: :invoices_queue

  def perform(id)
    puts "Generating Invoice for runningmenu_id: #{id}"
    Invoice.generate({runningmenu_id: id})
  end
end