class Destroyunfoundschedularfields < ActiveRecord::Migration[5.1]
  def change
    runningmenus = Runningmenu.where('delivery_at > ?', Time.current)
    runningmenus.each do |runningmenu|
      runningmenu.runningmenufields.each do |runningmenufield|
        unless runningmenufield.field.present?
          runningmenufield.destroy
        end
      end
    end
  end
end
