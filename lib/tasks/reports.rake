namespace :report do
  desc "Task to update orders not invoiced"
  task orders_not_invoiced: :environment do
    Report.orders_not_invoiced()
  end

  desc "Task to update orders not billed"
  task orders_not_billed: :environment do
    Report.orders_not_billed()
  end

  desc "Task to update average take rate"
  task average_take_rate: :environment do
    Report.average_take_rate()
  end
end
