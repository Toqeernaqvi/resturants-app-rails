class Setting < ApplicationRecord

  validates :minimum_amount, :distance_radius, :drive_radius, numericality: {:greater_than_or_equal_to => 0}

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  def self.latest
    order(created_at: :desc).first
  end

  def self.min_amount
    self.first.minimum_amount
  end

  def self.display_intercom
    self.first.display_intercom
  end

  def self.refresh_quickbooks_tokens
    setting = Setting.latest
    access_token = OAuth2::AccessToken.new($oauth2_client, setting.token, refresh_token: setting.refresh_token)
    new_access_token_object = access_token.refresh!
    setting.update_columns(token: new_access_token_object.token, refresh_token: new_access_token_object.refresh_token, token_expires_at: Time.at(new_access_token_object.expires_at).to_datetime)
  end

end
