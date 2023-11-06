class CuisinesMenu < ApplicationRecord
  belongs_to :cuisine
  belongs_to :runningmenu
  enum status: [:active, :deleted]

  # has_paper_trail if: lambda {|o| o.runningmenu.updated_from_frontend }
  before_destroy :cuisine_remove, if: lambda {|o| o.runningmenu.updated_from_frontend }

  def cuisine_remove
    if self.runningmenu.deleted_cuisines.present?
      deleted_cuisines = self.runningmenu.deleted_cuisines + ", " +  self.cuisine.name
    else
      deleted_cuisines = self.cuisine.name
    end
    self.runningmenu.update_column(:deleted_cuisines, deleted_cuisines)
  end
end
