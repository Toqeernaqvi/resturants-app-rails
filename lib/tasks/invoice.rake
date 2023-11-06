namespace :invoice do
  desc "Task to generate invoice of Order"
  task generate: :environment do
      Invoice.generate
  end
end
