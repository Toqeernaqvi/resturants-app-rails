class Populatemenus < ActiveRecord::Migration[5.1]
  def change
    Restaurant.all.each do |restaurant|
      gmenu = Gmenu.active.find_by(restaurant_id: restaurant.id, menu_type: Gmenu.menu_types[:dont_care])
      if gmenu.present? && restaurant.addresses.active.present?
        restaurant.addresses.active.each do |address|
          unless Menu.active.exists?(address_id: address.id, menu_type: Menu.menu_types[:lunch])
            if gmenu.gsections.active.present? || gmenu.gfooditems.active.present?
              menu = Menu.create(
                parent_id: gmenu.id,
                address_id: address.id,
                gmenu_id: gmenu.id,
                menu_type: Menu.menu_types[:lunch]
              )

              gmenu.gsections.active.each do |gsection|
                menu.sections.create(
                  parent_id: gsection.id,
                  gsection_id: gsection.id,
                  name: gsection.name,
                  description: gsection.description,
                  position: gsection.position
                )
              end
              gmenu.gfooditems.active.each do |gfooditem|
                menu.fooditems.create(
                  parent_id: gfooditem.id,
                  gfooditem_id: gfooditem.id,
                  name: gfooditem.name,
                  description: gfooditem.description,
                  price: gfooditem.price,
                  calories: gfooditem.calories,
                  spicy: gfooditem.spicy,
                  best_seller: gfooditem.best_seller,
                  skip_markup: gfooditem.skip_markup,
                  image: gfooditem.image,
                  position: gfooditem.position,
                  notes_to_restaurant: gfooditem.notes_to_restaurant
                )
              end

              gmenu.goptionsets.active.each do |goptionset|
                optionset = menu.optionsets.create(
                  parent_id: goptionset.id,
                  goptionset_id: goptionset.id,
                  name: goptionset.name,
                  required: goptionset.required,
                  start_limit: goptionset.start_limit,
                  end_limit: goptionset.end_limit,
                  position: goptionset.position
                )

                goptionset.goptions.active.each do |goption|
                  option = optionset.options.create(
                    parent_id: goption.id,
                    goption_id: goption.id,
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
                fooditem = Fooditem.active.find_by(parent_id: gfooditem.id, menu_id: menu.id)

                if fooditem.present?
                  fooditem.dietaries << gfooditem.dietaries if gfooditem.dietaries.present?
                  fooditem.ingredients << gfooditem.ingredients if gfooditem.ingredients.present?

                  gfooditem.gsections.active.each do |gsection|
                    section = Section.find_by(parent_id: gsection.id, menu_id: menu.id)

                    fooditem.sections << section if section.present?
                  end

                  gfooditem.goptionsets.active.each do |goptionset|
                    optionset = Optionset.find_by(parent_id: goptionset.id, menu_id: menu.id)

                    fooditem.optionsets << optionset if optionset.present?
                  end
                  fooditem.save
                end
              end
            end
          end
        end
      end
    end
  end
end
