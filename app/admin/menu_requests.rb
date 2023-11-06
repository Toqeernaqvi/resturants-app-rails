ActiveAdmin.register Menu, as: "MenuRequest" do
  menu parent: 'Restaurants', priority: 3
  config.batch_actions = false
  config.filters = false
  actions :all, :except => [:new, :edit, :destroy]
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end
  index do
    column :id
    column ("Address") {|m| m.address}
    column :draft_id
    column :menu_type
    column :request_status do |menu|
      if menu.approved?
        status_tag( :approved )
      elsif menu.pending?
        status_tag( :pending )
      else
        status_tag( :cancelled )
      end
    end

    actions do |menu|
      item('approve', approve_admin_menu_request_path(menu.id), class: :member_link)
      item('cancel', cancel_admin_menu_request_path(menu.id), class: :member_link)
    end
  end

  show do
    attributes_table do
      row :menu_type
      row :address
      row :request_status do |menu|
        if menu.approved?
          status_tag( :approved )
        elsif menu.pending?
          status_tag( :pending )
        else
          status_tag( :cancelled )
        end
      end
      row :draft_id

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

  member_action :approve, method: :get do
    menu = Menu.find params[:id]

    if menu.present? && menu.pending?
      if menu.sections.present?
        menu.sections.each do |section|
          Section.where(:id => section.draft_id).update(name: section.name, description: section.description, updated_at: section.updated_at)
        end
      end

      if   menu.fooditems.present?
        menu.fooditems.each do |fooditem|
          Fooditem.where(:id => fooditem.draft_id).update(name: fooditem.name, description: fooditem.description, notes_to_restaurant: fooditem.notes_to_restaurant, updated_at: fooditem.updated_at )

          if fooditem.dietaries.present?
            fooditem.dietaries.each do |dietary|
              Dietary.where(:id => dietary.draft_id).update(description: dietary.description, updated_at: dietary.updated_at)
            end
          end

          if fooditem.ingredients.present?
            fooditem.ingredients.each do |ingredient|
              Ingredient.where(:id => ingredient.draft_id).update(description: ingredient.description, updated_at: ingredient.updated_at)
            end
          end
        end
      end

      if menu.optionsets.present?
        menu.optionsets.each do |optionset|
          Optionset.where(:id => optionset.draft_id).update(name: optionset.name, required: optionset.required, start_limit: optionset.start_limit, end_limit: optionset.end_limit, updated_at: optionset.updated_at)

          optionset.options.each do |option|
            Option.where(:id => option.draft_id).update(description: option.description, calories: option.calories, price: option.price, updated_at: option.updated_at)

            if option.dietaries.present?
              option.dietaries.each do |dietary|
                Dietary.where(:id => dietary.draft_id).update(description: dietary.description, updated_at: dietary.updated_at)
              end
            end

            if option.ingredients.present?
              option.ingredients.each do |ingredient|
                Ingredient.where(:id => ingredient.draft_id).update(description: ingredient.description, updated_at: ingredient.updated_at)
              end
            end

          end
        end

        if menu.destroy
          redirect_to collection_path
        end

      end
    end

  end

  member_action :cancel, method: :get do
    menu = Menu.find params[:id]
    if menu.destroy
      redirect_to collection_path
    end
  end


  controller do
    def scoped_collection
      Menu.where.not(draft_id: nil )
    end
  end

end
