class ChangeCustomerTypeUsersShareMeetings < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :customer_id, :string
    change_column :share_meetings, :customer_id, :string
  end
end
