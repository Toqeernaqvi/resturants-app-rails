class Menu < ApplicationRecord
  #acts_as_paranoid

  belongs_to :address
  belongs_to :gmenu, optional: true
  has_many :sections, dependent: :destroy
  has_many :fooditems, dependent: :destroy
  has_many :optionsets, dependent: :destroy

  accepts_nested_attributes_for :sections, allow_destroy: true
  accepts_nested_attributes_for :fooditems, allow_destroy: true
  accepts_nested_attributes_for :optionsets, allow_destroy: true

  after_save :calculate_gross_price

  enum menu_type: [:dont_care, :lunch, :dinner, :breakfast, :buffet]
  enum spicy: [:no, :yes], _prefix: :spicy
  enum best_seller: [:no, :yes], _prefix: :best_seller
  enum status: [:active, :deleted]
  enum request_status: [:approved, :pending, :cancelled]
  enum parent_status: [:active, :deleted], _prefix: :parent_status
  after_save :update_dependents_statuses, if: lambda{|m| m.saved_change_to_status?}
  after_save :delete_images
  after_commit :reindex_restaurant_address

  def reindex_restaurant_address
    begin
      RestaurantAddressReindexJob.perform_later(self.address.id)
    rescue ArgumentError => e
      puts e
      return
    end  
  end

  def delete_images
    @fooditems = self.fooditems.select{|f| f if f.del_img == "1"}
    Fooditem.where(id: @fooditems.pluck(:id)).update_all(image: nil) if @fooditems.present?
  end

  def update_dependents_statuses
    if self.active?
      self.fooditems.where(parent_status: :active).update_all(status: :active)
      self.sections.where(parent_status: :active).update_all(status: :active)
      self.optionsets.each do |optionset|
        optionset.options.where(parent_status: :active).update_all(status: :active)
        optionset.parent_status_active? ? optionset.update_columns(status: :active) : optionset.update_columns(status: :deleted)
      end
    else
      self.fooditems.active.update_all(status: :deleted)
      self.sections.active.update_all(status: :deleted)
      self.optionsets.active.each do |optionset|
        optionset.options.active.update_all(status: :deleted)
        optionset.update_columns(status: :deleted)
      end
    end
  end

  def self.import(restaurant_id, address_id, menu_type, import_type, import_address_id)
    menu = Menu.active.find_by(address_id: import_address_id, menu_type: menu_type)
    if menu.present?
      if menu.sections.active.present?
        menu1 = Menu.create(
          parent_id: menu.id,
          address_id: address_id,
          menu_type: import_type
        )

        menu.sections.active.each do |gsection|
          menu1.sections.create(
            parent_id: gsection.id,
            name: gsection.name,
            description: gsection.description,
            position: gsection.position,
            section_type: gsection.section_type
          )
        end
        menu.fooditems.active.each do |gfooditem|
          fooditem = menu1.fooditems.create(
            parent_id: gfooditem.id,
            name: gfooditem.name,
            description: gfooditem.description,
            price: import_type == 'buffet' ? 0.0 : gfooditem.price,
            calories: gfooditem.calories,
            spicy: gfooditem.spicy,
            best_seller: gfooditem.best_seller,
            skip_markup: gfooditem.skip_markup,
            ignore_budget: gfooditem.ignore_budget,
            image: gfooditem.image,
            position: gfooditem.position,
            notes_to_restaurant: gfooditem.notes_to_restaurant,
            skip_nutritional_facts: true
          )
          gfooditem.nutritional_facts.each do |nutritional_fact|
            fooditem.nutritional_facts.create(nutrition_id: nutritional_fact.nutrition_id, value: nutritional_fact.value)
          end
        end

        menu.optionsets.active.each do |goptionset|
          optionset = menu1.optionsets.create(
            parent_id: goptionset.id,
            name: goptionset.name,
            required: goptionset.required,
            start_limit: goptionset.start_limit,
            end_limit: goptionset.end_limit,
            position: goptionset.position
          )

          goptionset.options.active.each do |goption|
            option = optionset.options.create(
              parent_id: goption.id,
              description: goption.description,
              price: goption.price,
              calories: goption.calories,
              position: goption.position,
              skip_nutritional_facts: true
            )

            goption.nutritional_facts.each do |nutritional_fact|
              option.nutritional_facts.create(nutrition_id: nutritional_fact.nutrition_id, value: nutritional_fact.value)
            end
            option.dietaries << goption.dietaries if goption.dietaries.present?
            option.ingredients << goption.ingredients if goption.ingredients.present?
            option.save
          end
        end

        if import_type == "buffet"
          menu1.address.update_columns(items_count: menu.address.items_count, minimum_discount_price: menu.address.minimum_discount_price, buffet_commission: menu.address.buffet_commission)
          # menu1.address.items_count = menu.address.items_count
          # menu1.address.minimum_discount_price = menu.address.minimum_discount_price
          # menu1.address.buffet_commission = menu.address.buffet_commission
          menu.address.dishsizes.each do |ds|
            menu1.address.dishsizes.create(title: ds.title, description: ds.description, serve_count: ds.serve_count)
          end
          # menu1.address.save
        end
        
        menu.fooditems.active.each do |gfooditem|
          fooditem = Fooditem.active.find_by(parent_id: gfooditem.id, menu_id: menu1.id)
          if fooditem.present?
            fooditem.dietaries << gfooditem.dietaries if gfooditem.dietaries.present?
            fooditem.ingredients << gfooditem.ingredients if gfooditem.ingredients.present?

            gfooditem.sections.active.each do |gsection|
              section = Section.find_by(parent_id: gsection.id, menu_id: menu1.id)

              fooditem.sections << section if section.present?
            end

            gfooditem.optionsets.active.each do |goptionset|
              optionset = Optionset.find_by(parent_id: goptionset.id, menu_id: menu1.id)

              fooditem.optionsets << optionset if optionset.present?
            end
            if gfooditem.dishsizes.present? && import_type == "buffet"
              gfooditem.dishsize_fooditems.joins(:dishsize, :fooditem).where("dishsizes.status = ? AND fooditems.status = ? ", Dishsize.statuses[:active], Fooditem.statuses[:active]).each do |df|
                fooditem.dishsize_fooditems.create(dishsize_id: menu1.address.dishsizes.find_by_title(df.dishsize.title).id, price: df.price)
              end
            end
            fooditem.save
          end
        end
        # menu1.save
        return {success: true, menu_id: menu1.id}
      else
        return {success: false, message: "No sections defined in #{menu.menu_type}  to import "}
      end
    else
      return {success: false, message: "No Menu exists to import."}
    end
  end

  def import_items(section, items)
    err_str = ""
    begin
      section = self.sections.active.find_or_initialize_by(name: section)
      if section.save
        items.each do |item|
          fooditem = self.fooditems.find_or_create_by(
            name: item["item_name"],
            description: item["item_description"],
            price: self.buffet? ? 0.0 : (item["item_price"].to_f/100.to_f)
          )
          fooditem.file_url = item["item_img"] if fooditem.image.blank?
          if fooditem.save
            item["options"].each do |optionset_|
              optionset = self.optionsets.find_or_create_by(
                name: optionset_["name"],
                start_limit: optionset_["min_choice_options"] || 0,
                end_limit: optionset_["max_choice_options"] || 0
              )
              optionset_["choice_option_list"].each do |option_|
                option = optionset.options.find_or_create_by(
                  description: option_["description"],
                  price: (option_["price"][:amount] || option_["price"]["amount"]).to_f/100.to_f
                )
              end
              fooditem.optionsets << optionset unless fooditem.optionsets.include?(optionset)
            end
          else
            err_str += fooditem.errors.full_messages
          end
          section.fooditems << fooditem unless section.fooditems.include?(fooditem)
        end
      else
        err_str += section.errors.full_messages
      end

    rescue StandardError => e
      err_str += e.message
    end
    err_str
  end

  def calculate_gross_price
    self.fooditems.active.each do |fooditem|
      price = fooditem.price
      fooditem.optionsets.active.each do |optionset|
        if optionset.required > 0 || optionset.start_limit > 0
          options = optionset.options.active.order(price: :asc).limit(optionset.start_limit)

          options.each do |option|
            price += option.price
          end
        end
      end
      fooditem.gross_price = price
      fooditem.save
    end
  end
end
