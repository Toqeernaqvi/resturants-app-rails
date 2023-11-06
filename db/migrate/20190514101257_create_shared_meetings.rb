class CreateSharedMeetings < ActiveRecord::Migration[5.1]
  def change
    create_table :share_meetings do |t|
    	t.references :user
    	t.references :runningmenu
    	t.string :email
    	t.string :token
    	t.timestamps
    end
  end
end
