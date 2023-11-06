namespace :quickbooks do
  desc "Task to refresh quickbook token before an hour completion"
  task refresh_token: :environment do
  	Setting.refresh_quickbooks_tokens
  end
end
