class Api::V1::Vendor::MenusController < Api::V1::Vendor::ApiController
  before_action :set_restaurant
  before_action :set_menu_draft, only: [:index]
  before_action :set_menu, only: [:update, :relate_fooditem, :fooditems, :dishsizes]
  before_action :set_fooditem, only: [:dishsizes]

  def update
    if @menu.update(menu_params)
      render json: {message: 'Your request have been submitted successfully'}
    else
      error(E_INTERNAL, @menu.errors.full_messages[0])
    end
  end

  def relate_fooditem
    if params[:menu][:sections_attributes].present?
      section = Section.find params[:menu][:sections_attributes][:id]
      section.fooditem_id = params[:menu][:sections_attributes][:fooditem_id]
      section.relate_fooditem
    end
    if params[:menu][:optionsets_attributes].present?
      optionset = Optionset.find params[:menu][:optionsets_attributes][:id]
      optionset.fooditem_id = params[:menu][:optionsets_attributes][:fooditem_id]
      optionset.add_fooditem = params[:menu][:optionsets_attributes][:add_fooditem]
      optionset.relate_fooditem
    end
    render json: {message: 'Your request have been submitted successfully'}
  end

  def fooditems
    if fooditem = @menu.fooditems.create(fooditem_params)
      render json: {menu_id: @menu.id, fooditem: fooditem, message: 'Fooditem created successfully'}
    else
      error(E_INTERNAL, fooditem.errors.full_messages[0])
    end
  end

  def dishsizes
    dishsize = nil
    if dishsize_params[:dishsize_id].present?
      dishsize = @restaurant.dishsizes.find_by_id(dishsize_params[:dishsize_id])
    else
      dishsize = @restaurant.dishsizes.create(dishsize_params.slice(:title, :serve_count))
    end
    if dishsize.present?
      if dishsize_params[:dishsize_destroy].present?
        @fooditem.dishsize_fooditems.where(dishsize_id: dishsize.id).destroy_all
      else
        @fooditem.dishsize_fooditems.create(dishsize_id: dishsize.id, price: dishsize_params[:price])
      end
      obj = @fooditem.dishsizes.active.select("dishsizes.id, title, description, serve_count, dishsize_fooditems.price").find_by(id: dishsize.id)
      obj = {id: obj.id, title: obj.title, serve_count: obj.serve_count, price: obj.price} unless obj.blank?
      render json: { dishsize: obj }
    else
      error(E_INTERNAL, dishsize&.errors&.full_messages[0])
    end
  end

  private

  def set_restaurant
    authorized_current_member = current_member.addresses_vendor.pluck(:address_id).include?(params["restaurant_id"].to_i) rescue nil
    if authorized_current_member.present?
      @restaurant = RestaurantAddress.find(params[:restaurant_id])
    else
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
  end

  def set_menu
    if params[:menu_id].present?
      arr = params[:menu_id].split("_")
      if arr.count > 1 && arr[0] == 'new'
        @menu = @restaurant.menus.active.find_or_create_by(menu_type: arr[1])
      end
    end
    @menu ||= @restaurant.menus.find_by_id(params[:id] || params[:menu_id])
    if @menu.blank?
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
  end

  def set_menu_draft
    case params[:menu_type]
    when "lunch"
      if @restaurant.menu_lunch.present?
        if MenuLunch.exists?(draft_id: @restaurant.menu_lunch.id)
          @menu = MenuLunch.find_by(draft_id: @restaurant.menu_lunch.id)
        end
      else
        render json: {message: "No menu present"}
      end
    when "dinner"
      if @restaurant.menu_dinner.present?
        if MenuDinner.exists?(draft_id: @restaurant.menu_dinner.id)
          @menu = MenuDinner.find_by(draft_id: @restaurant.menu_dinner.id)
        end
      else
        render json: {message: "No menu present"}
      end
    when "buffet"
      if @restaurant.menu_buffet.present?
        if MenuBuffet.exists?(draft_id: @restaurant.menu_buffet.id)
          @menu = MenuBuffet.find_by(draft_id: @restaurant.menu_buffet.id)
        end
      else
        render json: {message: "No menu present"}
      end
    else
      if @restaurant.menu_breakfast.present?
        if MenuBreakfast.exists?(draft_id: @restaurant.menu_breakfast.id)
          @menu = MenuBreakfast.find_by(draft_id: @restaurant.menu_breakfast.id)
        end
      else
        render json: {message: "No menu present"}
      end
    end
  end

  def set_fooditem
    @fooditem = @menu.fooditems.find_by_id(dishsize_params[:fooditem_id])
    if @fooditem.blank?
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
  end

  def fooditem_params
    params.require(:fooditem).permit(:name, :description, :price)
  end

  def dishsize_params
    params.require(:dishsize).permit(:title, :description, :serve_count, :price, :dishsize_id, :fooditem_id, :dishsize_destroy)
  end

  def menu_params
    params.require(:menu).permit(
      :address_id,
      :menu_type,
      :status,
      :draft_id,
      :request_status,
      sections_attributes: [
        :id,
        :draft_id,
        :parent_status,
        :position,
        :name,
        :description,
        :section_type,
        :fooditem_id
      ],
      fooditems_attributes: [
        :id,
        :draft_id,
        :parent_status,
        :name,
        :description,
        :price,
        :spicy,
        :best_seller,
        :skip_markup,
        :image,
        :notes_to_restaurant,
        nutritional_facts_attributes: [
          :id,
          :value
        ],
        dietary_ids: [],
        ingredient_ids: []
      ],
      optionsets_attributes: [
        :id,
        :draft_id,
        :parent_status,
        :position,
        :name,
        :required,
        :start_limit,
        :end_limit,
        :fooditem_id,
        :add_fooditem,
        options_attributes: [
          :id,
          :draft_id,
          :parent_status,
          :position,
          :description,
          :price,
          dietary_ids: [],
          ingredient_ids: []
        ],
       ]
    )
  end

end