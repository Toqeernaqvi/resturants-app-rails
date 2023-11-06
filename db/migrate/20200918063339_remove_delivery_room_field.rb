class RemoveDeliveryRoomField < ActiveRecord::Migration[5.1]
  def change
    Runningmenufield.joins(:field).where("fields.name ILIKE '%Delivery Room%'").destroy_all
    Field.where("name ILIKE '%Delivery Room%'").destroy_all
  end
end
