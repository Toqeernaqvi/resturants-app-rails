class Gmenu < ApplicationRecord
  #acts_as_paranoid

  belongs_to :restaurant
  has_many :gsections, dependent: :destroy
  has_many :gfooditems, dependent: :destroy
  has_many :goptionsets, dependent: :destroy

  accepts_nested_attributes_for :gsections, allow_destroy: true
  accepts_nested_attributes_for :gfooditems, allow_destroy: true
  accepts_nested_attributes_for :goptionsets, allow_destroy: true

  enum menu_type: [:dont_care, :lunch, :dinner, :breakfast]
  enum spicy: [:no, :yes], _prefix: :spicy
  enum best_seller: [:no, :yes], _prefix: :best_seller
  enum status: [:active, :deleted]
  after_save :update_dependents_statuses, if: lambda{|m| m.saved_change_to_status?}

  def update_dependents_statuses
    if self.active?
      self.gfooditems.each do |fooditem|
        if fooditem.parent_status_active?
          fooditem.active!
        else
          fooditem.deleted!
        end
      end
      self.gsections.each do |section|
        if section.parent_status_active?
          section.active!
        else
          section.deleted!
        end
      end
      self.goptionsets.each do |optionset|
        optionset.goptions.each do |option|
          if option.parent_status_active?
            option.active!
          else
            option.deleted!
          end
        end
        if optionset.parent_status_active?
          optionset.active!
        else
          optionset.deleted!
        end
      end
    else
      self.gfooditems.each do |fooditem|
        fooditem.deleted!
      end
      self.gsections.each do |section|
        section.deleted!
      end
      self.goptionsets.each do |optionset|
        optionset.goptions.each do |option|
          option.deleted!
        end
        optionset.deleted!
      end
    end
  end

  def self.import(restaurant_id, menu_type)
    gmenu = Gmenu.find_by(restaurant_id: restaurant_id, menu_type: Gmenu.menu_types[:dont_care])

    if Gmenu.exists?(restaurant_id: restaurant_id, menu_type: menu_type)
      return {success: false}
    else
      gmenu_new = Gmenu.create(
        parent_id: gmenu.id,
        restaurant_id: gmenu.restaurant_id,
        menu_type: menu_type
      )

      gmenu.gsections.active.each do |gsection|
        menusection = gmenu_new.gsections.create(
          parent_id: gsection.id,
          name: gsection.name,
          description: gsection.description,
          position: gsection.position
        )
      end

      gmenu.gfooditems.active.each do |gfooditem|
        gmenu_new.gfooditems.create(
          parent_id: gfooditem.id,
          name: gfooditem.name,
          description: gfooditem.description,
          price: gfooditem.price,
          calories: gfooditem.calories,
          spicy: gfooditem.spicy,
          best_seller: gfooditem.best_seller,
          skip_markup: gfooditem.skip_markup,
          ignore_budget: gfooditem.ignore_budget,
          image: gfooditem.image,
          position: gfooditem.position,
          notes_to_restaurant: gfooditem.notes_to_restaurant
        )
      end

      gmenu.goptionsets.active.each do |goptionset|
        optionset = gmenu_new.goptionsets.create(
          parent_id: goptionset.id,
          name: goptionset.name,
          required: goptionset.required,
          start_limit: goptionset.start_limit,
          end_limit: goptionset.end_limit,
          position: goptionset.position
        )

        goptionset.goptions.active.each do |goption|
          option = optionset.goptions.create(
            parent_id: goption.id,
            description: goption.description,
            price: goption.price,
            calories: goption.calories,
            position: goption.position
          )

            option.dietaries << goption.dietaries if goption.dietaries.present?
            option.ingredients << goption.ingredients if goption.ingredients.present?
          option.save
        end
      end

      gmenu.gfooditems.active.each do |gfooditem|
        gfooditem_new = Gfooditem.find_by(parent_id: gfooditem.id, gmenu_id: gmenu_new.id)
        if gfooditem_new.present?
          gfooditem_new.dietaries << gfooditem.dietaries if gfooditem.dietaries.present?
          gfooditem_new.ingredients << gfooditem.ingredients if gfooditem.ingredients.present?

          gfooditem.gsections.active.each do |gsection|
            gsection_new = Gsection.find_by(parent_id: gsection.id, gmenu_id: gmenu_new.id)

            gfooditem_new.gsections << gsection_new if gsection_new.present?
          end

          gfooditem.goptionsets.active.each do |goptionset|
            goptionset_new = Goptionset.find_by(parent_id: goptionset.id, gmenu_id: gmenu_new.id)

            gfooditem_new.goptionsets << goptionset_new if goptionset_new.present?
          end

          gfooditem_new.save
        end
      end

      return {success: true, menu_id: gmenu_new.id}
    end
  end
end
