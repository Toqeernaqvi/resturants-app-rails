# app/controllers/api/v1/favorites_controller.rb
class Api::V1::FavoritesController < Api::V1::ApiController
  before_action :set_fooditem, only: [:create, :destroy]
  
  def create
    @favorite  = @fooditem.favorites.find_or_initialize_by(user_id: current_member.id, company_id: current_member.company_id)
    if @favorite.save
      render :json => {message: "You favorited #{@fooditem.name}"}
    else
      error(E_INTERNAL, @favorite.errors.full_messages[0])
    end
  end

  def destroy
    @favorite = @fooditem.favorites.where(user_id: current_member.id).destroy_all
    render :json => {message: "Unfavorited #{@fooditem.name}"}
  end

  private

  def set_fooditem
    @fooditem = Fooditem.find_by_id(params[:fooditem_id])
    if @fooditem.blank?
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
  end

end
  