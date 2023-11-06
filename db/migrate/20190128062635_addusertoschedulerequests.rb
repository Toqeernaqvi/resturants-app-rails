class Addusertoschedulerequests < ActiveRecord::Migration[5.1]
  def change
    add_reference :runningmenu_requests, :user, index: true, foreign_key: true, after: :runningmenu_request_type

    add_reference :runningmenus, :runningmenu_request, index: true, foreign_key: true, after: :runningmenu_type

    create_table :cuisines_requests do |t|
      t.belongs_to :cuisine, index: true, foreign_key: true
      t.belongs_to :runningmenu_request, index: true, foreign_key: true
    end
  end
end
