json.dietaries do
  json.array! Dietary.active.all do |dietary|
    json.(dietary, :id, :name)
  end
end
json.ingredients do
  json.array! Ingredient.active.all do |ingredient|
    json.(ingredient, :id, :name)
  end
end
section_types = {}
Section.section_types.map{|k, v| section_types[k.titleize] = k}
json.section_types section_types
json.dishsizes @restaurant.dishsizes.active.uniq
if params[:menu_type].present?
  case params[:menu_type]
  when "lunch"
    if @restaurant.menu_lunch.present?
      @menu.present? ? "#{json.draft true}" : "#{json.draft false}"
      # json.sections do
      #   json.array! @menu.present? ? @menu.sections : @restaurant.menu_lunch.sections do |section|
      #     json.(
      #       section, :id, :name, :description, :parent_status
      #     )
      #   end
      # end
      json.menu_id @menu.present? ? @menu.id : @restaurant.menu_lunch.id
      json.sections do
        json.array! @menu.present? ? @menu.sections.active : @restaurant.menu_lunch.sections.active do |section|
          json.id section.id
          json.name section.name
          json.description section.description
          json.fooditems section.fooditems do |fooditem|
            json.(fooditem, :id, :name, :description, :price, :spicy, :best_seller, :skip_markup, :image, :notes_to_restaurant, :parent_status)
            json.rating fooditem.ratings.present? ? (fooditem.ratings.sum(:rating_value).to_f / fooditem.ratings.count.to_f) : "No ratings available"
            json.dietaries do
              json.array! fooditem.dietaries.uniq do |dietary|
                json.value dietary.id
                json.label dietary.name
              end
            end
            json.ingredients do
              json.array! fooditem.ingredients.uniq do |ingredient|
                json.value ingredient.id
                json.label ingredient.name
              end
            end
            json.optionsets do
              json.array! fooditem.optionsets.active.each do |optionset|
                json.id optionset.id
                json.name optionset.name
                json.required optionset.required
                json.start_limit optionset.start_limit
                json.end_limit optionset.end_limit
                json.options do
                  json.array! optionset.options.active.each do |option|
                    json.id option.id
                    json.description option.description
                    json.price option.price
                    json.nutritions do
                      json.array! option.nutritions do |nutrition|
                        json.id nutrition.id
                        json.name nutrition.name
                        json.value nutrition.value
                        json.childs NutritionalFact.joins(:nutrition).where(factable: option, nutritions: {parent_id: nutrition.nutrition_id } ) do |c|
                          json.id c.id
                          json.name c.nutrition.name
                          json.value c.value
                        end
                      end
                    end
                  end
                end
              end
            end
            json.nutritions do
              json.array! fooditem.nutritions do |nutrition|
                json.id nutrition.id
                json.name nutrition.name
                json.value nutrition.value
                json.childs NutritionalFact.joins(:nutrition).where(factable: fooditem, nutritions: {parent_id: nutrition.nutrition_id } ) do |c|
                  json.id c.id
                  json.name c.nutrition.name
                  json.value c.value
                end
              end
            end
          end
        end
      end
      # json.fooditems do
      #   json.array! @menu.present? ? @menu.fooditems : @restaurant.menu_lunch.fooditems do |fooditem|
      #     json.(
      #       fooditem, :id, :name, :description, :price, :calories, :spicy, :best_seller, :skip_markup, :image, :notes_to_restaurant, :parent_status )
      #       json.rating fooditem.ratings.present? ? (fooditem.ratings.sum(:rating_value).to_f / fooditem.ratings.count.to_f) : "No ratings available"
      #       json.dietaries do
      #         json.array! fooditem.dietaries.uniq do |dietary|
      #           json.value dietary.id
      #           json.label dietary.name
      #         end
      #       end
      #       json.ingredients do
      #         json.array! fooditem.ingredients.uniq do |ingredient|
      #           json.value ingredient.id
      #           json.label ingredient.name
      #         end
      #       end
      #       json.optionsets do
      #         json.array! fooditem.optionsets.each do |optionset|
      #           json.id optionset.id
      #           json.name optionset.name
      #           json.required optionset.required
      #           json.start_limit optionset.start_limit
      #           json.end_limit optionset.end_limit
      #           json.options do
      #             json.array! optionset.options.each do |option|
      #               json.id option.id
      #               json.description option.description
      #               json.price option.price
      #               json.calories option.calories
      #             end
      #           end
      #         end
      #       end
      #   end
      # end

      json.optionsets @menu.present? ? @menu.optionsets.active : @restaurant.menu_lunch.optionsets.active do |optionset|
        json.id optionset.id
        json.name optionset.name
        json.required optionset.required
        json.start_limit optionset.start_limit
        json.end_limit optionset.end_limit
        json.parent_status optionset.parent_status

        json.options optionset.options.active do |option|
          json.id option.id
          json.position option.position
          json.description option.description
          json.price option.price
          json.parent_status option.parent_status
          json.dietaries do
            json.array! option.dietaries.uniq do |dietary|
              json.value dietary.id
              json.label dietary.name
            end
          end
          json.ingredients do
            json.array! option.ingredients.uniq do |ingredient|
              json.value ingredient.id
              json.label ingredient.name
            end
          end
        end
      end
    end
  when "dinner"
    @menu.present? ? "#{json.draft true}" : "#{json.draft false}"
    if @restaurant.menu_dinner.present?
      # json.sections do
      #   json.array! @menu.present? ? @menu.sections : @restaurant.menu_dinner.sections do |section|
      #     json.(
      #       section, :id, :name, :description, :parent_status
      #     )
      #   end
      # end
      json.menu_id @menu.present? ? @menu.id : @restaurant.menu_dinner.id
      json.sections do
        json.array! @menu.present? ? @menu.sections.active : @restaurant.menu_dinner.sections.active do |section|
          json.id section.id
          json.name section.name
          json.description section.description
          json.fooditems section.fooditems do |fooditem|
            json.(fooditem, :id, :name, :description, :price, :spicy, :best_seller, :skip_markup, :image, :notes_to_restaurant, :parent_status)
            json.rating fooditem.ratings.present? ? (fooditem.ratings.sum(:rating_value).to_f / fooditem.ratings.count.to_f) : "No ratings available"
            json.dietaries do
              json.array! fooditem.dietaries.uniq do |dietary|
                json.value dietary.id
                json.label dietary.name
              end
            end
            json.ingredients do
              json.array! fooditem.ingredients.uniq do |ingredient|
                json.value ingredient.id
                json.label ingredient.name
              end
            end
            json.optionsets do
              json.array! fooditem.optionsets.active.each do |optionset|
                json.id optionset.id
                json.name optionset.name
                json.required optionset.required
                json.start_limit optionset.start_limit
                json.end_limit optionset.end_limit
                json.options do
                  json.array! optionset.options.active.each do |option|
                    json.id option.id
                    json.description option.description
                    json.price option.price
                    json.nutritions do
                      json.array! option.nutritions do |nutrition|
                        json.id nutrition.id
                        json.name nutrition.name
                        json.value nutrition.value
                        json.childs NutritionalFact.joins(:nutrition).where(factable: option, nutritions: {parent_id: nutrition.nutrition_id } ) do |c|
                          json.id c.id
                          json.name c.nutrition.name
                          json.value c.value
                        end
                      end
                    end
                  end
                end
              end
            end
            json.nutritions do
              json.array! fooditem.nutritions do |nutrition|
                json.id nutrition.id
                json.name nutrition.name
                json.value nutrition.value
                json.childs NutritionalFact.joins(:nutrition).where(factable: fooditem, nutritions: {parent_id: nutrition.nutrition_id } ) do |c|
                  json.id c.id
                  json.name c.nutrition.name
                  json.value c.value
                end
              end
            end
          end
        end
      end


      # json.fooditems do
      #   json.array! @menu.present? ? @menu.fooditems : @restaurant.menu_dinner.fooditems do |fooditem|
      #     json.(
      #       fooditem, :id, :name, :description, :price, :calories, :spicy, :best_seller, :skip_markup, :image, :notes_to_restaurant, :parent_status )
      #       json.dietaries do
      #         json.array! fooditem.dietaries.uniq do |dietary|
      #           json.value dietary.id
      #           json.label dietary.name
      #         end
      #       end
      #       json.ingredients do
      #         json.array! fooditem.ingredients.uniq do |ingredient|
      #           json.value ingredient.id
      #           json.label ingredient.name
      #         end
      #       end
      #       json.optionsets do
      #         json.array! fooditem.optionsets.each do |optionset|
      #           json.id optionset.id
      #           json.name optionset.name
      #           json.required optionset.required
      #           json.start_limit optionset.start_limit
      #           json.end_limit optionset.end_limit
      #           json.options do
      #             json.array! optionset.options.each do |option|
      #               json.id option.id
      #               json.description option.description
      #               json.price option.price
      #               json.calories option.calories
      #             end
      #           end
      #         end
      #       end
      #   end
      # end

      json.optionsets @menu.present? ? @menu.optionsets.active : @restaurant.menu_dinner.optionsets.active do |optionset|
        json.id optionset.id
        json.name optionset.name
        json.required optionset.required
        json.start_limit optionset.start_limit
        json.end_limit optionset.end_limit
        json.parent_status optionset.parent_status

        json.options optionset.options.active do |option|
          json.id option.id
          json.position option.position
          json.description option.description
          json.price option.price
          json.parent_status option.parent_status
          #json.dietary_ids option.dietary_ids
          json.dietaries do
            json.array! option.dietaries.uniq do |dietary|
              json.value dietary.id
              json.label dietary.name
            end
          end
          json.ingredients do
            json.array! option.ingredients.uniq do |ingredient|
              json.value ingredient.id
              json.label ingredient.name
            end
          end
         # json.ingredient_ids option.ingredient_ids
        end
      end
    end
  when "buffet"
    @menu.present? ? "#{json.draft true}" : "#{json.draft false}"
    json.menu_id @menu.present? ? @menu.id : @restaurant.menu_buffet.id
    if @restaurant.menu_buffet.present?
      json.sections do
        json.array! @menu.present? ? @menu.sections.active : @restaurant.menu_buffet.sections.active do |section|
          json.id section.id
          json.name section.name
          json.section_type section.section_type.titleize
          json.description section.description
          json.fooditems section.fooditems do |fooditem|
            json.(fooditem, :id, :name, :description, :spicy, :best_seller, :skip_markup, :image, :notes_to_restaurant, :parent_status)
            json.rating fooditem.ratings.present? ? (fooditem.ratings.sum(:rating_value).to_f / fooditem.ratings.count.to_f) : "No ratings available"
            json.dishsizes do
              json.array! fooditem.dishsizes.active.uniq do |dishsize|
                json.(
                  dishsize, :id, :title, :description, :serve_count
                )
                json.price fooditem.dishsize_fooditems.find_by(dishsize_id: dishsize.id).price
              end
            end
            json.dietaries do
              json.array! fooditem.dietaries.uniq do |dietary|
                json.value dietary.id
                json.label dietary.name
              end
            end
            json.ingredients do
              json.array! fooditem.ingredients.uniq do |ingredient|
                json.value ingredient.id
                json.label ingredient.name
              end
            end
            json.optionsets do
              json.array! fooditem.optionsets.active.each do |optionset|
                json.id optionset.id
                json.name optionset.name
                json.required optionset.required
                json.start_limit optionset.start_limit
                json.end_limit optionset.end_limit
                json.options do
                  json.array! optionset.options.active.each do |option|
                    json.id option.id
                    json.description option.description
                    json.price option.price
                    json.nutritions do
                      json.array! option.nutritions do |nutrition|
                        json.id nutrition.id
                        json.name nutrition.name
                        json.value nutrition.value
                        json.childs NutritionalFact.joins(:nutrition).where(factable: option, nutritions: {parent_id: nutrition.nutrition_id } ) do |c|
                          json.id c.id
                          json.name c.nutrition.name
                          json.value c.value
                        end
                      end
                    end
                  end
                end
              end
            end
            json.nutritions do
              json.array! fooditem.nutritions do |nutrition|
                json.id nutrition.id
                json.name nutrition.name
                json.value nutrition.value
                json.childs NutritionalFact.joins(:nutrition).where(factable: fooditem, nutritions: {parent_id: nutrition.nutrition_id } ) do |c|
                  json.id c.id
                  json.name c.nutrition.name
                  json.value c.value
                end
              end
            end
          end
        end
      end

      json.optionsets @menu.present? ? @menu.optionsets.active : @restaurant.menu_buffet.optionsets.active do |optionset|
        json.id optionset.id
        json.name optionset.name
        json.required optionset.required
        json.start_limit optionset.start_limit
        json.end_limit optionset.end_limit
        json.parent_status optionset.parent_status

        json.options optionset.options.active do |option|
          json.id option.id
          json.position option.position
          json.description option.description
          json.price option.price
          json.parent_status option.parent_status
          #json.dietary_ids option.dietary_ids
          json.dietaries do
            json.array! option.dietaries.uniq do |dietary|
              json.value dietary.id
              json.label dietary.name
            end
          end
          json.ingredients do
            json.array! option.ingredients.uniq do |ingredient|
              json.value ingredient.id
              json.label ingredient.name
            end
          end
        end
      end
    end
  else
    if @restaurant.menu_breakfast.present?
      @menu.present? ? "#{json.draft true}" : "#{json.draft false}"
      json.menu_id @menu.present? ? @menu.id : @restaurant.menu_breakfast.id
      json.sections do
        json.array! @menu.present? ? @menu.sections.active : @restaurant.menu_breakfast.sections.active do |section|
          json.id section.id
          json.name section.name
          json.description section.description
          json.fooditems section.fooditems do |fooditem|
            json.(fooditem, :id, :name, :description, :price, :spicy, :best_seller, :skip_markup, :image, :notes_to_restaurant, :parent_status)
            json.rating fooditem.ratings.present? ? (fooditem.ratings.sum(:rating_value).to_f / fooditem.ratings.count.to_f) : "No ratings available"
            json.dietaries do
              json.array! fooditem.dietaries.uniq do |dietary|
                json.value dietary.id
                json.label dietary.name
              end
            end
            json.ingredients do
              json.array! fooditem.ingredients.uniq do |ingredient|
                json.value ingredient.id
                json.label ingredient.name
              end
            end
            json.optionsets do
              json.array! fooditem.optionsets.active.each do |optionset|
                json.id optionset.id
                json.name optionset.name
                json.required optionset.required
                json.start_limit optionset.start_limit
                json.end_limit optionset.end_limit
                json.options do
                  json.array! optionset.options.active.each do |option|
                    json.id option.id
                    json.description option.description
                    json.price option.price
                    json.nutritions do
                      json.array! option.nutritions do |nutrition|
                        json.id nutrition.id
                        json.name nutrition.name
                        json.value nutrition.value
                        json.childs NutritionalFact.joins(:nutrition).where(factable: option, nutritions: {parent_id: nutrition.nutrition_id } ) do |c|
                          json.id c.id
                          json.name c.nutrition.name
                          json.value c.value
                        end
                      end
                    end
                  end
                end
              end
            end
            json.nutritions do
              json.array! fooditem.nutritions do |nutrition|
                json.id nutrition.id
                json.name nutrition.name
                json.value nutrition.value
                json.childs NutritionalFact.joins(:nutrition).where(factable: fooditem, nutritions: {parent_id: nutrition.nutrition_id } ) do |c|
                  json.id c.id
                  json.name c.nutrition.name
                  json.value c.value
                end
              end
            end
          end
        end
      end

      # json.sections do
      #   json.array! @breakfastMenu.present? ? @breakfastMenu.sections : @restaurant.menu_breakfast.sections do |section|
      #     json.(
      #       section, :id, :name, :description, :parent_status
      #     )
      #   end
      # end

      # json.fooditems do
      #   json.array! @breakfastMenu.present? ? @breakfastMenu.fooditems : @restaurant.menu_breakfast.fooditems do |fooditem|
      #     json.(
      #       fooditem, :id, :name, :description, :price, :calories, :spicy, :best_seller, :skip_markup, :image, :notes_to_restaurant, :parent_status )
      #       json.dietaries do
      #         json.array! fooditem.dietaries.uniq do |dietary|
      #           json.value dietary.id
      #           json.label dietary.name
      #         end
      #       end
      #       json.ingredients do
      #         json.array! fooditem.ingredients.uniq do |ingredient|
      #           json.value ingredient.id
      #           json.label ingredient.name
      #         end
      #       end
      #       json.optionsets do
      #         json.array! fooditem.optionsets.each do |optionset|
      #           json.id optionset.id
      #           json.name optionset.name
      #           json.required optionset.required
      #           json.start_limit optionset.start_limit
      #           json.end_limit optionset.end_limit
      #           json.options do
      #             json.array! optionset.options.each do |option|
      #               json.id option.id
      #               json.description option.description
      #               json.price option.price
      #               json.calories option.calories
      #             end
      #           end
      #         end
      #       end
      #   end
      # end

      json.optionsets @breakfastMenu.present? ? @breakfastMenu.optionsets.active : @restaurant.menu_breakfast.optionsets.active do |optionset|
        json.id optionset.id
        json.name optionset.name
        json.required optionset.required
        json.start_limit optionset.start_limit
        json.end_limit optionset.end_limit
        json.parent_status optionset.parent_status

        json.options optionset.options.active do |option|
          json.id option.id
          json.position option.position
          json.description option.description
          json.price option.price
          json.parent_status option.parent_status
          # json.dietary_ids option.dietary_ids
          # json.ingredient_ids option.ingredient_ids
          json.dietaries do
            json.array! option.dietaries.uniq do |dietary|
              json.value dietary.id
              json.label dietary.name
            end
          end
          json.ingredients do
            json.array! option.ingredients.uniq do |ingredient|
              json.value ingredient.id
              json.label ingredient.name
            end
          end
        end
      end
    end
  end
end
