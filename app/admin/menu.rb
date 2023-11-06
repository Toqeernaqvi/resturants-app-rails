ActiveAdmin.register Menu, as: 'Menu' do
  menu false
  config.batch_actions = false
  config.clear_action_items!

  permit_params do
    permitted = [
      :address_id,
      :menu_type,
      :status,
      sections_attributes: [
        :id,
        :_destroy,
        :position,
        :name,
        :description,
        :parent_status,
        :section_type
      ],
      fooditems_attributes: [
        :id,
        :_destroy,
        :name,
        :description,
        :price,
        :spicy,
        :best_seller,
        :skip_markup,
        :ignore_budget,
        :image,
        :del_img,
        :notes_to_restaurant,
        :parent_status,
        # :tag_list,
        nutritional_facts_attributes: [
          :id,
          :value
        ],
        dietary_ids: [],
        ingredient_ids: [],
        tag_list: [],
        dishsize_fooditems_attributes: [
          :id,
          :_destroy,
          :dishsize_id,
          :price
        ],
      ],
      optionsets_attributes: [
        :id,
        :_destroy,
        :position,
        :name,
        :required,
        :start_limit,
        :end_limit,
        :parent_status,
        options_attributes: [
          :id,
          :_destroy,
          :position,
          :description,
          :price,
          :parent_status,
          nutritional_facts_attributes: [
            :id,
            :value
          ],
          dietary_ids: [],
          ingredient_ids: []
        ],
      ]
    ]
  end

  action_item :edit,  only: [ :show ] do
    link_to "Edit Menu", edit_admin_restaurant_address_menu_path(params[:restaurant_id], params[:address_id], resource.id)
  end

  # action_item :import, only: [:new] do
  #   if params[:type] != 'breakfast'
  #     link_to 'Import Breakfast Menu', import_admin_restaurant_address_menus_path(params[:restaurant_id], params[:address_id], type: params[:type], import_type: 'breakfast'), { data: {method: :post} }
  #   end
  # end

  # action_item :import, only: [:new] do
  #   if params[:type] != 'lunch'
  #     # link_to 'Import Lunch Menu', import_admin_restaurant_address_menus_path(params[:restaurant_id], params[:address_id], type: params[:type], import_type: 'lunch'), { data: {method: :post} }
  #   end
  # end

  action_item :import, only: [:new] do
    if Menu.active.joins(:address).where('addresses.addressable_id = ? AND menus.menu_type != ?', params[:restaurant_id], Menu.menu_types[:dont_care]).exists?
      link_to "Import Menu", populate_menus_admin_menus_path(restaurant_id: params[:restaurant_id], address_id: params[:address_id], type: params[:type]), remote: true
    end
  end

  # action_item :import, only: [:new] do
  #   if params[:type] != 'dinner'
  #     link_to 'Import Dinner Menu', import_admin_restaurant_address_menus_path(params[:restaurant_id], params[:address_id], type: params[:type], import_type: 'dinner'), { data: {method: :post} }
  #   end
  # end

  action_item :menu_billing, only: [:edit, :new] do
    link_to "Billing", menu_billing_admin_menus_path(address_id: params[:address_id]), class: [:member_link] if (params[:type].present? && params[:type] == 'buffet') || (resource.present? && resource.buffet?)
  end
  action_item :relate_fooditems, only: [:edit] do
    link_to 'Relate Fooditems', relate_fooditems_admin_restaurant_address_menu_path(params[:restaurant_id], params[:address_id], id: resource.id)
  end
  action_item :relate_options, only: [:edit] do
    link_to 'Relate Option Sets', relate_optionsets_admin_restaurant_address_menu_path(params[:restaurant_id], params[:address_id], id: resource.id)
  end
  # action_item :relate_dishsizes, only: [:edit] do
  #   link_to "Relate Dish Sizes", relate_dishsizes_admin_restaurant_address_menu_path(restaurant_id: params[:restaurant_id],id: resource.id), class: [:member_link] if resource.present? && resource.buffet?
  # end
  action_item :fooditems_nutritions, only: [:edit] do
    link_to 'Fooditems Nutritions', fooditems_nutritions_admin_restaurant_address_menu_path(params[:restaurant_id], params[:address_id], id: resource.id)
  end
  action_item :options_nutritions, only: [:edit] do
    link_to 'Options Nutritions', options_nutritions_admin_restaurant_address_menu_path(params[:restaurant_id], params[:address_id], id: resource.id)
  end
  action_item :relate_options, only: [:edit] do
    link_to "Delete Menu", delete_admin_menu_path(restaurant_id: params[:restaurant_id],id: resource.id), class: [:member_link, :delete_btn]
  end
  # action_item :set_scheduler_for_menu, only: [:edit] do
  #   link_to "Login frontend", set_scheduler_for_menu_admin_menu_path(restaurant_id: params[:restaurant_id]), target: "_blank"
  # end

  action_item :only => [:edit, :new] do
    link_to 'Upload Json', upload_json_admin_menus_path(restaurant_id: params[:restaurant_id], address_id: params[:address_id], id: resource&.id, type: params[:type]), class: 'upload_json', for: 'uploadJSON_', remote: true
  end

  index do
    column :id
    column :menu_type
    actions
  end

  csv do
    column :id
    column :menu_type
  end

  form do |f|
    f.inputs do
      f.input :address_id, input_html: { value: (f.object.new_record? ? params[:address_id] : f.object.address_id) }, as: :hidden
      f.input :menu_type, input_html: { value: (f.object.new_record? ? params[:type] : f.object.menu_type) }, as: :hidden
      f.has_many :sections, sortable: :position, sortable_start: 1, heading: nil do |section|
        section.input :name, label: false, placeholder: 'Name', input_html: {class: 'name'}
        section.input :description, label: false, placeholder: 'description', input_html: {class: 'description'}
        section.input :section_type, as: :select, input_html: {class: 'section_type'} if (f.object.new_record? ? params[:type] : f.object.menu_type) == 'buffet'
        unless section.object.new_record?
          section.input :parent_status, as: :boolean, label: "Delete", :checked_value => "deleted", :unchecked_value => "active"
        end
      end
      f.has_many :fooditems, heading: nil do |fooditem|
        fooditem.input :name, label: 'Name', input_html: {class: 'name'}
        unless (params[:type].present? && params[:type] == 'buffet') || (f.object.present? && f.object.menu_type == 'buffet')
          fooditem.input :price, label: 'Price', input_html: { min: '0', step: '0.1', class: 'price', onclick: "this.select();" }
        else
          fooditem.input :price, label: false, input_html: { min: '0', step: '0.1', class: 'hideMenuItem_ price' }
        end
        fooditem.input :image, label: false, as: :file, hint: image_tag(fooditem.object.image.thumb)
        fooditem.input :del_img, as: :boolean, input_html: {class: 'hideListItem_'}, label: ""
        fooditem.input :spicy, label: 'Spicy', as: :boolean, input_html: { class: 'spicy' }
        fooditem.input :best_seller, label: 'Best Seller', as: :boolean, input_html: { class: 'best_seller' }
        fooditem.input :skip_markup, label: 'Skip Markup', as: :boolean, input_html: { class: 'skip_markup' }
        fooditem.input :ignore_budget, label: 'Ignore Budget', as: :boolean, input_html: { class: (f.object.new_record? && params[:type] == 'buffet') || f.object.buffet? ? 'ignore_budget hideMenuItem_' : 'ignore_budget' }
        fooditem.input :description, label: 'Description', input_html: { class: 'description' }
        # binding.pry
        # fooditem.input :tag_list, as: :tags, input_html: {'data-modal': "menu_fooditems_attributes_#{fooditem.index}"}, collection: ActsAsTaggableOn::Tag.joins(:taggings).where(taggings: {tenant: nil}).order(id: :asc).uniq.pluck(:name)
        fooditem.input :tag_list, as: :select, multiple: true, input_html: {class: 'tags_input'}, collection: ActsAsTaggableOn::Tag.joins(:taggings).where(taggings: {tenant: nil}).order(id: :asc).uniq.pluck(:name)
        fooditem.input :dietary_ids, label: 'Dieraties', collection: Dietary.active.all, input_html: { multiple: true }
        fooditem.input :ingredient_ids, label: 'Ingredients', collection: Ingredient.active.all, input_html: { multiple: true }
        fooditem.input :notes_to_restaurant, input_html: {class: 'notes_to_restaurant'}
        if (f.object.new_record? && params[:type].present? && params[:type] == 'buffet') || (!f.object.new_record? && f.object.menu_type == 'buffet')
          fooditem.has_many :dishsize_fooditems, heading: nil, allow_destroy: true do |dishsize_fooditem|
            dishsize_fooditem.input :dishsize_id, as: :select, label: "Dishsize", collection: f.object.new_record? ? Address.find_by_id(params[:address_id]).dishsizes.active&.pluck(:title, :id) : f.object.address.dishsizes.active&.pluck(:title, :id)
            dishsize_fooditem.input :price, label: 'Price($)', input_html: { min: '0', step: '0.1' }
          end
        end
        unless fooditem.object.new_record?
          fooditem.input :parent_status, as: :boolean, label: "Delete", :checked_value => "deleted", :unchecked_value => "active"
        end
      end
      f.has_many :optionsets, sortable: :position, sortable_start: 1, heading: nil do |optionset|
        optionset.input :name, label:"Name", input_html: { class: 'name' }
        optionset.input :required, label:false, as: :boolean, input_html: { class: 'required' }
        optionset.input :start_limit, label: 'Must Have', placeholder:'Start', input_html: { class: 'start_limit', onclick: "this.select();" }
        optionset.input :end_limit, label: 'Upto', placeholder:'End', input_html: { class: 'end_limit', onclick: "this.select();" }

        optionset.has_many :options, sortable: :position, sortable_start: 1, heading: nil do |option|
          option.input :description, label: 'Description', input_html: { class: 'description' }
          option.input :price, label: 'Price', input_html: { min: '0', step: '0.1', class: 'price', onclick: "this.select();" }
          option.input :dietary_ids, label: 'Dieraties', collection: Dietary.active.all, input_html: { multiple: true }
          option.input :ingredient_ids, label: 'Ingredients', collection: Ingredient.active.all, input_html: { multiple: true }
          unless option.object.new_record?
            option.input :parent_status, as: :boolean, label: "Delete", :checked_value => "deleted", :unchecked_value => "active"
          end
        end
        unless optionset.object.new_record?
          optionset.input :parent_status, as: :boolean, label: "Delete", :checked_value => "deleted", :unchecked_value => "active"
        end
      end
    end
    f.actions do
      f.action(:submit)
      f.cancel_link
      # f.action :cancel, :as => :link, :label => "Cancel"
    end
  end

  show do
    attributes_table do
      row :menu_type

      div :class => "wrapper_sections" do
        render partial: 'admin/sections/section', locals: {sections: resource.sections.order(position: :asc)} if resource.sections.first.present?
      end

      div :class => "wrapper_fooditems" do
        div 'Fooditems', :class => "Fooditems" do
        end
        ol :class => "f_items" do
          resource.fooditems.each do |fooditem|
            li do
              render partial: 'admin/fooditems/fooditem', locals: {fooditem: fooditem} if fooditem.present?
            end
          end
        end

      end
      div :class => "wrapper_optionset" do
        # menu = Menu.find_by(params[:address_id], params[:type])
        div 'Option Sets', :class => "optionset" do
        end
        ol do
          resource.optionsets.order(position: :asc).each do |optionset|
            li do
              render partial: 'admin/optionsets/optionset', locals: {optionset: optionset, options: optionset.options} if optionset.name.present?
            end
          end
        end

      end
      # row 'Options' do
      #   render partial: 'admin/options/option', locals: {options: resource.optionsets.option}
      # end
    end
  end

  member_action :import, method: :post do
    return_val = Menu.import(params[:restaurant_id], params[:address_id], params[:type], params[:import_type], params[:import_address_id])
    if return_val[:success]
      redirect_to edit_admin_restaurant_address_menu_path(params[:restaurant_id], params[:address_id], return_val[:menu_id]), notice: "Menu have been successfully imported."
    else
      redirect_to admin_restaurant_addresses_path(params[:restaurant_id]), notice: return_val[:message]
    end
  end

  member_action :relate_fooditems do
    render 'admin/menu/relate_fooditems'
  end
  member_action :relate_optionsets do
    render 'admin/menu/relate_optionsets'
  end

  member_action :relate_dishsizes do
    render 'admin/menu/relate_dishsizes'
  end

  member_action :fooditems_nutritions do
    render 'admin/menu/fooditems_nutritions'
  end

  member_action :options_nutritions do
    render 'admin/menu/options_nutritions'
  end

  collection_action :menu_billing do
    @address = Address.find_by_id params[:address_id]
    render 'admin/menu/billing'
  end

  # member_action :set_scheduler_for_menu do
  #   company = Company.find_by_name ENV["TEST_COMPANY"]
  #   company_admin = company.company_admins.active.first
  #   company_address = company.addresses.active.first
  #   restaurant_address = resource.address
  #   meal_type = resource.menu_type
  #   date = Date.today + 1.week
  #   scheduler = Runningmenu.joins(:addresses).where("addresses.id=? and runningmenus.company_id=? and DATE(delivery_at)>? and runningmenu_type=? ",restaurant_address.id,company.id,Date.yesterday,Runningmenu.runningmenu_types[meal_type]).last
  #   if scheduler.blank?
  #     scheduler = Runningmenu.new(runningmenu_type: meal_type,
  #       company_id: company.id,
  #       address_id: company_address.id,
  #       delivery_at: date,
  #       activation_at: date - 4.days,
  #       cutoff_at: date - 3.days,
  #       admin_cutoff_at: date - 2.days,
  #       runningmenu_name: "To see menu",
  #       user_id: current_admin_user.id,
  #       per_meal_budget: 10,
  #       orders_count: 1,
  #       skip_for_menu_login: "skip beverages restaurant addition",
  #       status: Runningmenu.statuses.keys[0]
  #     )
  #     scheduler.addresses << restaurant_address
  #     scheduler.save(validate: false)
  #   end
  #   redirect_to login_admin_scheduler_path(id: company_admin.id, scheduler: scheduler)
  # end

  member_action :related_fooditems, method: :post do
    params[:menu][:sections_attributes].each do |k, section_|
      section = Section.find(section_[:id])
      section.fooditems.destroy_all
      section_[:fooditems][:fooditem_id].each do |fooditem_id_|
        if fooditem_id_.to_i > 0
          fooditem_id = Fooditem.find(fooditem_id_)
          section.fooditems << fooditem_id
        end
        section.save
      end
    end

    redirect_to edit_admin_restaurant_address_menu_path, notice: "Food items have been successfully saved."
  end

  member_action :related_optionsets, method: :post do
    params[:menu][:fooditems_attributes].each do |k, fooditem_|
      fooditem = Fooditem.find(fooditem_[:id])
      fooditem.optionsets.destroy_all
      fooditem_[:optionsets][:optionset_id].each do |optionset_id_|
        if optionset_id_.to_i > 0
          optionset_id = Optionset.find(optionset_id_)
          fooditem.optionsets << optionset_id
        end
        fooditem.save
      end
    end

    redirect_to edit_admin_restaurant_address_menu_path, notice: "Optionsets have been successfully saved."
  end

  member_action :related_dishsizes, method: :post do
    params[:menu][:fooditems_attributes].each do |k, fooditem_|
      fooditem = Fooditem.find(fooditem_[:id])
      if fooditem_[:dishsizes][:dishsize_id].count == 1
        flash[:error] = "Please select dishsizes for each fooditems"
        redirect_to relate_dishsizes_admin_restaurant_address_menu_path(restaurant_id: resource.address.addressable.id,id: resource.id, address_id: resource.address_id) and return if resource.valid?
      else
        fooditem.dishsizes.destroy_all
        fooditem.dishsizes << Dishsize.where(id: fooditem_[:dishsizes][:dishsize_id].map{|d| d.to_i})
        fooditem.save
      end
    end

    redirect_to edit_admin_restaurant_address_menu_path, notice: "Dish Sizes have been successfully saved."
  end

  member_action :delete, method: :get do
    resource.update(status: :deleted,parent_status: :deleted)
    redirect_to admin_restaurant_addresses_path(params[:restaurant_id])
  end

  collection_action :populate_menus, method: :get do
    @restaurant = Restaurant.find(params[:restaurant_id])
    respond_to do |format|
      format.js { render "populate_menus", :locals => {:type => params[:type]} }
    end
  end
  
  collection_action :upload_json, method: [:get, :post] do
    if request.post?
      file = params[:UploadJson].read
      sections = JSON.parse(file)
      error_log = []
      if params[:id].blank?
        menu = Menu.active.find_or_create_by(address_id: params[:address_id], menu_type: params[:type])
      else
        menu = resource
      end
      return if menu.blank?

      sections.each do |section, items|
        error_log << menu.import_items(section, items)
      end
      error_log = error_log.compact
      if error_log.compact.present?
      end
      if error_log.join.blank?
        redirect_to edit_admin_restaurant_address_menu_path(params[:restaurant_id], params[:address_id], menu.id), notice: "Menu have been successfully imported."
      else
        redirect_to admin_restaurant_addresses_path(params[:restaurant_id]), alert: error_log.join("<br />")
      end
    end
    # return_val = Menu.import(params[:restaurant_id], params[:address_id], params[:type], params[:import_type], params[:import_address_id])
    # if return_val[:success]
    #   redirect_to edit_admin_restaurant_address_menu_path(params[:restaurant_id], params[:address_id], return_val[:menu_id]), notice: "Menu have been successfully imported."
    # else
    #   redirect_to admin_restaurant_addresses_path(params[:restaurant_id]), notice: return_val[:message]
    # end
  end

  controller do
    skip_before_action :verify_authenticity_token, only: [:upload_json]

    def index
      redirect_to admin_restaurant_addresses_path(params[:restaurant_id])
    end

    def create
      super do |format|
        if resource.errors.messages.any?
          flash[:error] = resource.errors.full_messages[0].include?("Fooditems dishsize fooditems base") ? resource.errors.full_messages[0].gsub("Fooditems dishsize fooditems base", "") : (resource.errors.full_messages[0].include?("dishsize fooditems")? resource.errors.full_messages[0].gsub("dishsize fooditems", "") : resource.errors.full_messages[0])
          redirect_to edit_admin_restaurant_address_menu_path(address_id: resource.address_id, id: resource.id, restaurant_id: resource.address.addressable.id) and return if resource.valid?
        elsif resource.buffet? && !resource.address.dishsizes.exists?
          flash[:error] = "Please add atleast one dishsizes"
          redirect_to menu_billing_admin_menus_path(address_id: resource.address_id) and return if resource.valid?
        elsif resource.buffet? && resource.fooditems.count != resource.fooditems.joins(:dishsizes).uniq.count
          flash[:error] = "Please relate dishsizes to fooditems"
          # redirect_to relate_dishsizes_admin_restaurant_address_menu_path(restaurant_id: resource.address.addressable.id,id: resource.id, address_id: resource.address_id) and return if resource.valid?
          redirect_to edit_admin_restaurant_address_menu_path(address_id: resource.address_id, id: resource.id, restaurant_id: resource.address.addressable.id) and return if resource.valid?
        else
          flash[:notice] = "Menu created successfully"
          redirect_to admin_restaurant_address_menu_path(resource.address.addressable_id, resource.address_id, resource.id) and return if resource.valid?
        end
      end
    end

    def destroy
      menu = Menu.find_by_id(params[:id])
      if menu.destroy
        redirect_to admin_restaurant_addresses_path(params[:restaurant_id]), notice: "Menu deleted successfully"
      end
    end

    def update
      super do |format|
        if resource.errors.messages.any?
          flash[:error] = resource.errors.full_messages[0].include?("Fooditems dishsize fooditems base") ? resource.errors.full_messages[0].gsub("Fooditems dishsize fooditems base", "") : (resource.errors.full_messages[0].include?("dishsize fooditems")? resource.errors.full_messages[0].gsub("dishsize fooditems", "") : resource.errors.full_messages[0])
          if resource.errors.full_messages[0].include?("Fooditems nutritional facts")
            redirect_to fooditems_nutritions_admin_restaurant_address_menu_path(params[:restaurant_id], params[:address_id], id: resource.id) and return
          elsif resource.errors.full_messages[0].include?("Optionsets options nutritional facts")
            redirect_to options_nutritions_admin_restaurant_address_menu_path(params[:restaurant_id], params[:address_id], id: resource.id) and return
          else
            redirect_to edit_admin_restaurant_address_menu_path(address_id: resource.address_id, id: resource.id, restaurant_id: resource.address.addressable.id) and return if resource.valid?
          end
        elsif resource.buffet? && !resource.address.dishsizes.exists?
          flash[:error] = "Please add atleast one dishsizes"
          redirect_to menu_billing_admin_menus_path(address_id: resource.address_id) and return if resource.valid?
        elsif resource.buffet? && resource.fooditems.count != resource.fooditems.joins(:dishsizes).uniq.count
          flash[:error] = "Please relate dishsizes to fooditems"
          redirect_to edit_admin_restaurant_address_menu_path(address_id: resource.address_id, id: resource.id, restaurant_id: resource.address.addressable.id) and return if resource.valid?
        else
          if request.referrer.include?("fooditems_nutritions")
            flash[:notice] = "Fooditems nutritions updated successfully"
            redirect_to edit_admin_restaurant_address_menu_path and return if resource.valid?
          elsif request.referrer.include?("options_nutritions")
            flash[:notice] = "Options nutritions updated successfully"
            redirect_to edit_admin_restaurant_address_menu_path and return if resource.valid?
          else
            flash[:notice] = "Menu updated successfully"
            redirect_to admin_restaurant_address_menu_path(resource.address.addressable_id, resource.address_id, resource.id) and return if resource.valid?
          end
        end
      end
    end
  end
end
