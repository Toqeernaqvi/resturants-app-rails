class AddAttrsToSettingsForQuickbook < ActiveRecord::Migration[5.1]
  def change
    add_column :settings, :realmid, :string
    add_column :settings, :token, :text
    add_column :settings, :refresh_token, :string
    add_column :settings, :token_expires_at, :datetime
  end
end
