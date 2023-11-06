class RecurringDynamicSection < ApplicationRecord
  acts_as_ordered_taggable
  has_many :addresses_recurring_schedulers, dependent: :destroy
  belongs_to :recurring_scheduler, optional: true

  validates :name, presence: true
  
  after_commit :create_address_runningmenu, on: [:create, :update]

  def create_address_runningmenu
    tagged_restaurant_address_ids = Fooditem.active.joins(:tags, :menu).where(tags: { id: self.tags.pluck(:id).uniq}).pluck(:address_id).uniq
    self.addresses_recurring_schedulers.where.not(address_id: tagged_restaurant_address_ids).destroy_all
    if tagged_restaurant_address_ids.any?
      tagged_restaurant_address_ids.each do |tagged_restaurant_address_id|
        unless self.recurring_scheduler.addresses_recurring_schedulers.where(address_id: tagged_restaurant_address_id).exists?
          self.recurring_scheduler.addresses_recurring_schedulers.create(address_id: tagged_restaurant_address_id, recurring_dynamic_section_id: self.id)
        end
      end
    end
  end
end