class MoveOrdersfieldsDataToRunningmenusfields < ActiveRecord::Migration[5.1]
  def change
  	Runningmenu.unscoped.each do |schedular|
  		order = schedular.orders.last
  		unless order.blank?
	  		order.orderfields.each do |orderfield|
	  			Runningmenufield.find_or_create_by(runningmenu_id: schedular.id, field_id: orderfield.field_id, fieldoption_id: orderfield.fieldoption_id, field_type: orderfield.field_type, value: orderfield.value)
	  		end
	  	end		
  	end
  end
end