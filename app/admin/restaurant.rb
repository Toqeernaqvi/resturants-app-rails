ActiveAdmin.register Restaurant, as: 'Restaurant' do
  menu parent: 'Restaurants', priority: 1
  config.batch_actions = false
  actions :all, except: :destroy

  permit_params do
    permitted = [:name, :preferred_vendor, :time_zone, cuisine_ids: []]
  end

  action_item :map_view, only: [:index] do
    link_to 'Map View', admin_restaurants_map_view_path(request.parameters[:q])
  end

  index do
    column :id
    column :name
    column :status do |restaurant|
      if restaurant.active?
        status_tag( :active )
      elsif restaurant.deleted?
        status_tag( :deleted )
      end
    end
    actions do |restaurant|
      if restaurant.active?
        item('Delete', delete_admin_restaurant_path(restaurant.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_restaurant_path(restaurant.id) , class: [:member_link, :active_btn])
      end
      item('Locations', admin_restaurant_addresses_path(restaurant), class: :member_link)
      # item('Global Menu', edit_admin_restaurant_gmenu_path(restaurant, restaurant.gmenus.first), class: :member_link)
      # if restaurant.gmenu_breakfast.present?
      #   (item 'Global Breakfast Menu', edit_admin_restaurant_gmenu_path(restaurant_id: restaurant.id, id: restaurant.gmenu_breakfast.id), class: :member_link)
      # else
      #   (item 'Global Breakfast Menu', new_admin_restaurant_gmenu_path(restaurant_id: restaurant.id, type: 'breakfast'), class: :member_link)
      # end
      # if restaurant.gmenu_lunch.present?
      #   (item 'Global Lunch Menu', edit_admin_restaurant_gmenu_path(restaurant_id: restaurant.id, id: restaurant.gmenu_lunch.id), class: :member_link)
      # else
      #   (item 'Global Lunch Menu', new_admin_restaurant_gmenu_path(restaurant_id: restaurant.id, type: 'lunch'), class: :member_link)
      # end
      # if restaurant.gmenu_dinner.present?
      #   (item 'Global Dinner Menu', edit_admin_restaurant_gmenu_path(restaurant, id: restaurant.gmenu_dinner.id), class: :member_link)
      # else
      #   (item 'Global Dinner Menu', new_admin_restaurant_gmenu_path(restaurant, type: 'dinner'), class: :member_link)
      # end
    end
  end

  csv do
    column :id
    column :name
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :preferred_vendor, as: :boolean, label: "Preferred Vendor"
      f.input :time_zone, as: :select, collection: ActiveSupport::TimeZone::MAPPING.collect {|k, v| [k,v]}
      f.input :cuisine_ids, label: 'Cuisines', as: :tags, collection: Cuisine.active.all
    end
    f.actions do
      f.action(:submit)
      f.cancel_link
    end
  end

  show do
    attributes_table do
      row :name
      row 'Cuisines' do |r|
        raw(r.cuisines.map(&:name).join("<br>"))
      end
      panel "Addresses" do
        table_for restaurant.addresses do
          column ("Name") {|a| a.address_line}
          column :street
          column :city
          column :state
          column :zip
        end
      end
      panel "Audit log" do
        # render partial: '/active_admin/versions/restaurant_model', locals: {versions: (resource.versions.includes(:item)+PaperTrail::Version.joins(:version_associations).where("version_associations.foreign_key_id = ? AND version_associations.foreign_type = ?",resource.id,"Restaurant").includes(:item)).sort_by(&:created_at).reverse}
        render partial: '/active_admin/versions/restaurant_model', locals: {versions: resource.versions.includes(:item).sort_by(&:created_at).reverse}
      end
    end
  end

  member_action :delete, method: :get do
    restaurant = Restaurant.find(params[:id])
    ids = restaurant.addresses.active.pluck(:id)
    if Runningmenu.joins(:addresses).where("runningmenus.delivery_at > ? AND runningmenus.status != ? AND addresses.id IN (?)", Time.current, Runningmenu.statuses[:cancelled], ids).blank?
      if restaurant.active?
        restaurant.deleted!
        redirect_to admin_restaurants_path, notice: "Restaurant has been successfully deleted"
      end
    else
      redirect_to admin_restaurants_path, alert: "Restaurant #{restaurant.name} cannot be delete as its locations have some active meetings"
    end
  end

  member_action :active, method: :get do
    restaurant = Restaurant.find(params[:id])
    if restaurant.deleted?
      restaurant.active!
      redirect_to admin_restaurants_path, notice: "Restaurant has been successfully active"
    end
  end

  controller do
    before_action :set_paper_trail_whodunnit
  end

  filter :name
  filter :preferred_vendor,  as: :select, collection: [['Yes', true]]
  filter :menu_type_in, label: 'Menu Type', :as => :select, collection: ["Breakfast", "Lunch", "Dinner", "Buffet"]
  filter :status, as: :select, collection: -> { Restaurant.statuses }
  filter :addresses_zip, as: :select, collection: proc { RestaurantAddress.active.pluck(:zip).uniq }
  filter :commission_greater_than_0_in, label: "Commission > 0",  as: :select, collection: [['Yes', 'Yes']]
  filter :cuisines, label: 'Cuisines', as: :select, collection: proc{ Cuisine.active.all.pluck(:name, :id) }, multiple: true
  filter :marketplace_in, label: 'Marketplace', as: :select, collection: [['Yes', true],['No', false]]
end
