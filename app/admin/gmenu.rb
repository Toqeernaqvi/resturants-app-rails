ActiveAdmin.register Gmenu, as: 'Gmenu' do
  belongs_to :restaurant
  actions :all, :except => :destroy

  menu false
  config.batch_actions = false

  permit_params do
    permitted = [
      :menu_type,
      :status,
      gsections_attributes: [
        :id,
        :_destroy,
        :position,
        :name,
        :description,
        :parent_status
      ],
      gfooditems_attributes: [
        :id,
        :_destroy,
        :name,
        :description,
        :price,
        :calories,
        :spicy,
        :best_seller,
        :skip_markup,
        :ignore_budget,
        :image,
        :notes_to_restaurant,
        :parent_status,
        dietary_ids: [],
        ingredient_ids: []
      ],
      goptionsets_attributes: [
        :id,
        :_destroy,
        :position,
        :name,
        :required,
        :start_limit,
        :end_limit,
        :parent_status,
        goptions_attributes: [
          :id,
          :_destroy,
          :position,
          :description,
          :price,
          :calories,
          :parent_status,
          dietary_ids: [],
          ingredient_ids: []
        ],
      ],
    ]
  end

  action_item :import, only: [:new] do
    if params[:type] == 'breakfast'
      link_to 'Import Breakfast Menu', import_admin_restaurant_gmenus_path(params[:restaurant_id], type: params[:type]), { data: {method: :post} }
    elsif params[:type] == 'lunch'
      link_to 'Import Global Menu', import_admin_restaurant_gmenus_path(params[:restaurant_id], type: params[:type]), { data: {method: :post} }
    elsif params[:type] == 'dinner'
      link_to 'Import Dinner Menu', import_admin_restaurant_gmenus_path(params[:restaurant_id], type: params[:type]), { data: {method: :post} }
    end
  end

  action_item :relate_gfooditems, only: [:edit] do
    gmenu = Gmenu.find_by_restaurant_id(params[:restaurant_id])
    link_to 'Relate Global Fooditems', relate_gfooditems_admin_restaurant_gmenu_path(params[:restaurant_id], id: resource.id) if gmenu.gsections.present?
  end

  action_item :relate_goptions, only: [:edit] do
    gmenu = Gmenu.find_by_restaurant_id(params[:restaurant_id])
    link_to 'Relate Global Optionsets', relate_goptionsets_admin_restaurant_gmenu_path(params[:restaurant_id], id: resource.id) if gmenu.gsections.present?
  end

  form do |f|
    f.inputs do
      if params[:type].present?
        type = params[:type]
      elsif resource.menu_type.present?
        type = resource.menu_type
      else
        type = 'dont_care'
      end

      f.input :menu_type, input_html: { value: type }, as: :hidden
      f.has_many :gsections, sortable: :position, sortable_start: 1, new_record: 'Add New Global Section', heading: nil do |section|
        section.input :name, label: false, placeholder: 'Name', input_html: {class: 'name'}
        section.input :description, label: false, placeholder: 'description', input_html: {class: 'description'}
        unless section.object.new_record?
          section.input :parent_status, as: :boolean, label: "Delete", :checked_value => "deleted", :unchecked_value => "active"
        end
      end
      f.has_many :gfooditems, new_record: 'Add New Global Fooditem', heading: nil do |fooditem|
        fooditem.input :name, label: 'Name', input_html: {class: 'name'}
        fooditem.input :description, label: 'Description', input_html: { class: 'description' }
        fooditem.input :price, label: 'Price', input_html: { min: '0', step: '0.1', class: 'price', onclick: "this.select();" }
        fooditem.input :calories, label: 'Calories', input_html: { class: 'calories', onclick: "this.select();" }
        fooditem.input :spicy, label: 'Spicy', as: :boolean, input_html: { class: 'spicy' }
        fooditem.input :best_seller, label: 'Best Seller', as: :boolean, input_html: { class: 'best_seller' }
        fooditem.input :skip_markup, label: 'Skip Markup', as: :boolean, input_html: { class: 'skip_markup' }
        fooditem.input :ignore_budget, label: 'Ignore Budget', as: :boolean, input_html: { class: 'ignore_budget' }
        fooditem.input :dietary_ids, label: 'Dieraties', collection: Dietary.active.all, input_html: { multiple: true }
        fooditem.input :ingredient_ids, label: 'Ingredients', collection: Ingredient.active.all, input_html: { multiple: true }
        fooditem.input :image, label: false, as: :file, hint: image_tag(fooditem.object.image.thumb)
        fooditem.input :notes_to_restaurant, input_html: {class: 'notes_to_restaurant'}
        unless fooditem.object.new_record?
          fooditem.input :parent_status, as: :boolean, label: "Delete", :checked_value => "deleted", :unchecked_value => "active"
        end
      end
      f.has_many :goptionsets, sortable: :position, sortable_start: 1,new_record: 'Add New Global Optionset', heading: nil do |optionset|
        optionset.input :name, label:false, placeholder:'Name', input_html: { class: 'name' }
        optionset.input :required, label: false, as: :boolean, input_html: { class: 'required' }
        optionset.input :start_limit, label: 'Must Have', placeholder:'Start', input_html: { class: 'start_limit', onclick: "this.select();" }
        optionset.input :end_limit, label: 'Upto', placeholder:'End', input_html: { class: 'end_limit', onclick: "this.select();" }
        optionset.has_many :goptions, sortable: :position, sortable_start: 1, new_record: 'Add New Global Option', heading: nil do |option|
          option.input :description, label: 'Description', input_html: { class: 'description' }
          option.input :price, label: 'Price', input_html: { min: '0', step: '0.1', class: 'price', onclick: "this.select();" }
          option.input :calories, label: 'Calories', input_html: { class: 'calories', onclick: "this.select();" }
          option.input :dietary_ids, label: 'Dietaries', collection: Dietary.active.all, input_html: { multiple: true }
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
    end
  end

  show do
    attributes_table do
      row :menu_type
      div :class => "wrapper_sections" do
        render partial: 'admin/gsections/gsection', locals: {gsections: resource.gsections.order(position: :asc)} if resource.gsections.present?
      end

      div :class => "wrapper_fooditems" do
        div 'Fooditems', :class => "Fooditems" do
        end
        ol :class => "f_items" do
          resource.gfooditems.each do |gfooditem|
            li do
              render partial: 'admin/gfooditems/gfooditem', locals: {gfooditem: gfooditem} if gfooditem.present?
            end
          end
        end
      end
      div :class => "wrapper_optionset" do
        # gmenu = Gmenu.find_by_restaurant_id(params[:restaurant_id])
        div 'Option Sets', :class => "optionset" do
        end
        ol do
          resource.goptionsets.order(position: :asc).each do |goptionset|
            li do
              render partial: 'admin/goptionsets/goptionset', locals: {goptionset: goptionset, goptions: goptionset.goptions} if goptionset.name.present?
            end
          end
        end
      end
    end
  end

  member_action :import, method: :post do
    return_val = Gmenu.import(params[:restaurant_id], params[:type])

    if return_val[:success]
      redirect_to edit_admin_restaurant_gmenu_path(params[:restaurant_id], return_val[:menu_id]), notice: "Menu have been successfully imported."
    else
      redirect_to admin_restaurants_path, notice: "Menu was already setup."
    end
  end

  member_action :relate_gfooditems do
    render 'admin/gmenu/relate_gfooditems'
  end
  member_action :relate_goptionsets do
    render 'admin/gmenu/relate_goptionsets'
  end

  member_action :related_gfooditems, method: :post do
    params[:gmenu][:gsections_attributes].each do |k, gsection_|
      gsection = Gsection.find(gsection_[:id])
      gsection.gfooditems.destroy_all
      gsection_[:gfooditems][:gfooditem_id].each do |gfooditem_id_|
        if gfooditem_id_.to_i > 0
          gfooditem_id = Gfooditem.find(gfooditem_id_)
          gsection.gfooditems << gfooditem_id
        end
        gsection.save
      end
    end

    redirect_to edit_admin_restaurant_gmenu_path, notice: "Global fooditems have been successfully saved."
  end

  member_action :related_goptionsets, method: :post do
    params[:gmenu][:gfooditems_attributes].each do |k, gfooditem_|
      gfooditem = Gfooditem.find(gfooditem_[:id])
      gfooditem.goptionsets.destroy_all
      gfooditem_[:goptionsets][:goptionset_id].each do |goptionset_id_|
        if goptionset_id_.to_i > 0
          goptionset_id = Goptionset.find(goptionset_id_)
          gfooditem.goptionsets << goptionset_id
        end
        gfooditem.save
      end
    end

    redirect_to edit_admin_restaurant_gmenu_path, notice: "Global optionsets have been successfully saved."
  end

  controller do
    def index
      redirect_to admin_restaurants_path
    end

    def edit
      if resource.gsections.count == 0
        resource.gsections.build
      end
      if resource.gfooditems.count == 0
        resource.gfooditems.build
      end
      if resource.goptionsets.count == 0
        resource.goptionsets.build
        if resource.goptionsets.first.goptions.count == 0
          resource.goptionsets.first.goptions.build
        end
      end
    end
  end
end
