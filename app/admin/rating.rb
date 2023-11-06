ActiveAdmin.register Rating do
  menu parent: 'Logs'
  config.batch_actions = false
  actions :all, :except => [:new, :create, :edit, :destroy, :update]

  index do
    column :id
    column :user do |r|
      User.find(r.user_id).name
    end
    column :schedule do |r|
      r.runningmenu rescue ""
    end
    column :order do |r|
      r.order rescue ""
    end
    column :company do |r|
      r.user.company
    end
    column :item_type
    column :item_name
    column :restaurant_name
    column :restaurant_location
    column 'Rating', :rating_value
    column :comment
    column 'Rated at', :created_at
    actions do |rating|
      if rating.active?
        item('Delete', delete_admin_rating_path(rating.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_rating_path(rating.id) , class: [:member_link, :active_btn])
      end
    end
  end

  csv do
    column :id
    column :user do |r|
      User.find(r.user_id).name
    end
    column :schedule do |r|
      "schedule #"+r.runningmenu.id.to_s rescue ""
    end
    column :order do |r|
      "order #"+r.order.id.to_s rescue ""
    end
    column :company do |r|
      r.user.company.name
    end
    column :item_type
    column :item_name
    column :restaurant_name
    column :restaurant_location
    column :rating
    column :comment
    column :rated_at
  end

  show do
    attributes_table do
      row :id
      row :user do |r|
        User.find(r.user_id).name
      end
      row :company do |r|
        r.user.company
      end
      row 'Item Type' do |r|
        if r.ratingable_type == 'Address'
          "Restaurant"
        elsif r.ratingable_type == 'Runningmenu'
          "Services"
        else
          r.ratingable_type
        end
      end
      row 'Item Name' do |r|
        if r.ratingable_type == 'Runningmenu'
          r.ratingable.runningmenu_name
        elsif r.ratingable_type == 'Fooditem'
          r.ratingable.name
        end
      end
      row 'Restaurant Name', :ratingable do |r|
        if r.ratingable_type == 'Address'
          r.ratingable.addressable.name
        elsif r.ratingable_type == 'Fooditem'
          r.restaurant.name
        end
      end
      row 'Restaurant Location', :ratingable do |r|
        if r.ratingable_type == 'Address'
          r.ratingable.address_line
        elsif r.ratingable_type == 'Fooditem'
          r.restaurant_address.address_line
        end
      end
      row 'Rating' do |r|
        r.rating_value
      end
      row :comment
      row 'Rated at' do |r|
        r.created_at
      end
    end
  end

  member_action :delete, method: :get do
    rating = Rating.find(params[:id])
    if rating.parent_status_active? || rating.active?
      rating.parent_status_deleted!
      redirect_to admin_ratings_path, notice: "Rating has been successfully deleted"
    end
  end

  member_action :active, method: :get do
    rating = Rating.find(params[:id])
    if rating.parent_status_deleted? || rating.deleted?
      rating.parent_status_active!
      redirect_to admin_ratings_path, notice: "Rating has been successfully deleted"
    end
  end

  filter :user_id, as: :select, label: "User Name", collection: proc { User.distinct.joins(:ratings).map{ |u| [u.name, u.id]} }
  filter :user_company_id, as: :select, label: "Company Name", collection: proc { Company.distinct.joins(:users => :ratings).select(:name, :id) }
  filter :created_at, label: 'Rated At', as: :date_range
  # filter :ratingable_of_Fooditem_type_menu_address_addressable_of_Restaurant_type_id_eq, as: :select, label: "Restaurant", collection: proc { Restaurant.active.pluck(:name, :id)}
  filter :rating_value, label: "Rating"
  filter :comment
  filter :restaurant_id, as: :search_select_filter, url: proc { restaurants_admin_users_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'
  # filter :rate_in, label: "Restaurant Name", as: :select, collection: proc { Rating.find_by_sql("SELECT distinct restaurants.name AS name, addresses.addressable_id AS id from ratings INNER JOIN addresses ON addresses.id = ratings.ratingable_id INNER JOIN restaurants ON restaurants.id = addresses.addressable_id WHERE ratings.ratingable_type = 'Address'") }
end
