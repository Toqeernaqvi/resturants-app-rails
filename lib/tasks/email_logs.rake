namespace :email_logs do
  desc "Task to remove data older then 1 year"
  
  task remove_old_logs: :environment do
    EmailLog.where("created_at < ?", Time.current-1.year).select(:id).find_in_batches(batch_size: 1000).each do |ids|
      EmailLog.where(id: ids).destroy_all 
    end
  end
end
