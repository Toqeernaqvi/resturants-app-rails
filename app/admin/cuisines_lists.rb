ActiveAdmin.register Cuisineslist do
  menu false
  config.batch_actions = false
  actions :all, :except => :destroy

  permit_params do
    permitted = [
      :name,
      :menu_type,
      addresses_cuisineslists_attributes: [
        :id,
        :address_id,
        :cuisineslist_id,
        :position,
        :_destroy
      ]
    ]
  end
  index do
    column :id
    column :name
    column :menu_type
    column :status do |cuisinelist|
      if cuisinelist.active?
        status_tag( :active )
      else
        status_tag( :deleted )
      end
    end
    actions do |cuisinelist|
      if cuisinelist.active?
        item('Delete', delete_admin_cuisineslist_path(cuisinelist.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_cuisineslist_path(cuisinelist.id) , class: [:member_link, :active_btn])
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name#, label: false
      if f.object.new_record?
        f.input :menu_type
      else
        f.input :menu_type, input_html: { disabled: true }
      end
      f.semantic_errors :base
      f.semantic_errors :addresses_cuisineslists
      if f.object.new_record? && f.object.errors.blank?
        f.object.addresses_cuisineslists.build()
      end
      f.has_many :addresses_cuisineslists, heading: nil, allow_destroy: true, :sortable => :position, new_record: '+' do |rs|
        rs.input :id, as: :hidden
        rs.input :position, as: :hidden
        rs.input :address_id, as: :search_select, label: rs.object.position.to_s, required: false, url: restaurant_addresses_admin_cuisineslists_path, fields: [:address_line], display_name: 'name', minimum_input_length: 3, order_by: 'address_line_asc'
      end
      f.actions
    end
  end

  show do
    attributes_table do
      row :name, :menu_type
    end
    panel "" do
      table_for cuisineslist.addresses_cuisineslists.order(:position) do
        column :position
        column :address
      end
    end
  end

   member_action :delete, method: :get do
    cuisineslist = Cuisineslist.find(params[:id])
    if cuisineslist.active?
      cuisineslist.deleted!
      redirect_to admin_cuisineslists_path, notice: "Cuisines list has been successfully deleted"
    end
  end

  member_action :active, method: :get do
    cuisineslist = Cuisineslist.find(params[:id])
    if cuisineslist.deleted?
      cuisineslist.active!
      redirect_to admin_cuisineslists_path, notice: "Cuisines list haas been successfully active"
    end
  end

  collection_action :restaurant_addresses, method: :get do
    addresses = RestaurantAddress.active.joins(:restaurant, :menus).where("addresses.enable_self_service = ?", false).where("menus.menu_type = #{Menu.menu_types[params[:menu_type]]} AND restaurants.status = #{Restaurant.statuses[:active]} AND (restaurants.name ILIKE :prefix OR address_line ILIKE :prefix)", prefix: "%#{params[:q][:groupings]["0"]["address_line_contains"]}%").distinct
    render json: addresses.collect {|addr| {:id => addr.id, :name => addr.name} }
  end

  filter :name
  
end