class AddNameToShareMeetings < ActiveRecord::Migration[5.1]
  def change
    add_column :share_meetings, :first_name, :string, after: :customer_id
    add_column :share_meetings, :last_name, :string, after: :customer_id
  end
end
