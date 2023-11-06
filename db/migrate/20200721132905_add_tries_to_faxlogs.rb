class AddTriesToFaxlogs < ActiveRecord::Migration[5.1]
  def change
    add_column :faxlogs, :retry_time, :datetime
    add_column :faxlogs, :tries, :integer, default: 0
  end
end
