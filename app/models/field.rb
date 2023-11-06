class Field < ApplicationRecord
  #acts_as_paranoid

  belongs_to :company, optional: true

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  has_many :fieldoptions, dependent: :destroy
  accepts_nested_attributes_for :fieldoptions, allow_destroy: true

  validates :name, presence: true

  enum field_type: [:dropdown, :text]
  enum status: [:active, :deleted]

  after_save :update_status, if: lambda{|m| m.saved_change_to_status?}

  def update_status
    runningmenus = Runningmenu.where('company_id = ? AND delivery_at > ?', self.company.id, Time.current)
    if self.deleted?
      if self.dropdown?
        self.fieldoptions.each do |fieldoption|
          fieldoption.deleted!
        end
      end
      runningmenus.each do |runningmenu|
        runningmenu.runningmenufields.where(field_id: self.id).each do |runningmenufield|
          runningmenufield.destroy
        end
      end
    else
      if self.dropdown?
        self.fieldoptions.each do |fieldoption|
            fieldoption.active!
        end
      end
    end
  end

  def as_json(options = nil)
    super({ only: [:id, :field_type, :name, :required]}.merge(options || {}))
  end
end
