class AddCuisinesOrdersToSchedulars < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :orders_count, :integer, after: :admin_cutoff_at, default: 0
    add_column :runningmenus, :menu_type, :integer, after: :admin_cutoff_at, default: 0
    add_column :runningmenu_requests, :menu_type, :integer, after: :runningmenu_request_type, default: 0
    add_column :runningmenu_requests, :schedular_check, :boolean, default: false

    add_column :runningmenus, :special_request, :text
    add_column :runningmenu_requests, :special_request, :text

    create_table :cuisines_menus do |t|
      t.belongs_to :cuisine, index: true, foreign_key: true
      t.belongs_to :runningmenu, index: true, foreign_key: true
    end
  end
end
