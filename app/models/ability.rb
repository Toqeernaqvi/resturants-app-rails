class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
     if user.admin?
       can :manage, :all
     elsif user.developer?
       can :manage, :all
       cannot :manage, RestaurantBilling
       cannot :manage, Invoice
     elsif user.operations?
       can :manage, :all
       cannot :manage, RestaurantBilling
       cannot :manage, Invoice
       cannot :manage, Company
     end
  end
end
