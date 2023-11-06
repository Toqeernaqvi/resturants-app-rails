oauth_params = {
  site: "https://appcenter.intuit.com/connect/oauth2",
  authorize_url: "https://appcenter.intuit.com/connect/oauth2",
  token_url: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
}
$oauth2_client = OAuth2::Client.new(ENV['OAUTH_CLIENT_ID'], ENV['OAUTH_CLIENT_SECRET'], oauth_params)

if Rails.env != 'production'
  Quickbooks.sandbox_mode = true
end