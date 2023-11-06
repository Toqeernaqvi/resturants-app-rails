class DynamicSection < ApplicationRecord
  acts_as_ordered_taggable
  has_many :addresses_runningmenus, dependent: :destroy
  belongs_to :runningmenu, optional: true

  validates :name, presence: true
  
  after_commit :create_address_runningmenu, on: [:create, :update]

  def create_address_runningmenu
    tagged_restaurant_address_ids = Fooditem.active.joins(:tags, :menu).where(tags: { id: self.tags.pluck(:id).uniq}).pluck(:address_id).uniq
    self.addresses_runningmenus.where.not(address_id: tagged_restaurant_address_ids).destroy_all
    if tagged_restaurant_address_ids.any?
      tagged_restaurant_address_ids.each do |tagged_restaurant_address_id|
        unless self.runningmenu.addresses_runningmenus.where(address_id: tagged_restaurant_address_id).exists?
          self.runningmenu.addresses_runningmenus.create(address_id: tagged_restaurant_address_id, dynamic_section_id: self.id)
        end
      end
    end
  end
end