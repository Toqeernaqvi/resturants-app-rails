module FooditemHelper

  def user_favorite(user, fooditem)
    fooditem.favorites.where(user_id: user.id).exists?
  end

  def self.new_fooditem(fooditem, current_member)
    new_fooditem = false
    if Runningmenu.joins(:addresses_runningmenus).where(addresses_runningmenus: { address_id: fooditem.menu.address_id }).where(company_id: current_member.company_id).where("runningmenus.created_at BETWEEN ? AND ?", Time.current-7.days ,Time.current).present?
      new_fooditem = false
    else
      if fooditem.created_at < Time.current && fooditem.created_at > Time.current-7.days
        new_fooditem = true
      else
        new_fooditem = false
      end
    end
    new_fooditem
  end

end
