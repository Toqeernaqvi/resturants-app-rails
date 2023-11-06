class PopulateSchedulerBudget < ActiveRecord::Migration[5.1]
  def change
  	Runningmenu.includes(:company).where("per_meal_budget <= ?", 0).each do |scheduler|
  		scheduler.update_column(:per_meal_budget, scheduler.company.user_meal_budget)
  	end
  end
end
