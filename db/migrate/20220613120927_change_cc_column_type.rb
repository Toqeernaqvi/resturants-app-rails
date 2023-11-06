class ChangeCcColumnType < ActiveRecord::Migration[5.1]
  def self.up
    change_column :email_logs, :cc, :text
  end
  
  def self.down
    change_column :email_logs, :cc, :string
  end

end
