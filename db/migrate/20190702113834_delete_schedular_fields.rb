class DeleteSchedularFields < ActiveRecord::Migration[5.1]
  def change
    Runningmenu.where("delivery_at > ?", Time.current).each do |runningmenu|
      if runningmenu.runningmenufields.present?
        runningmenu.runningmenufields.joins(:field).where("fields.company_id != ?", runningmenu.company_id).destroy_all
      end
    end
  end
end
