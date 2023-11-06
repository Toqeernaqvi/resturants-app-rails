class ImportFooditems
  def call
    file_path = File.new(Rails.root.join('app/assets/csvs/fooditems.csv'))
    spreadsheet = Roo::Spreadsheet.open(file_path)

    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      restaurant = Restaurant.find_by(vendor_id: row['VendorID'])
      if restaurant.present?
        gmenu = restaurant.gmenus.first
        section_name = row['SectionName'].present? ? row['SectionName'] : 'Others'

        gfooditem = gmenu.gfooditems.new(
          name: row['Title'],
          description: row['Description'],
          price: row['VendorPrice'],
          item_id: row['ID'],
          calories: row['CaloryInfo'].to_i,
          old_image: row['ImageURL']
        )
        gfooditem.save(validate: false)

        gsection = gmenu.gsections.find_by(name: section_name)
        unless gsection.present?
          gsection = gmenu.gsections.create(
            name: section_name
          )
        end

        if gfooditem.present?
          if gsection.present?
            gsection.gfooditems << gfooditem
          end

          optionsets = row['SetsOfOptions'].to_s.split(',')
          optionsets.each do |optionset|
            if optionset.to_i > 0
              optionset = Goptionset.find_by(choice_type: optionset)
              if optionset.present?
                gfooditem.goptionsets << optionset
              end
            end
          end
          dietaries = row['Allergens'].to_s.split(',')
          dietaries.each do |dietary|
            if dietary.to_i > 0
              if dietary.to_i == 2
                dietaryFind = Dietary.find_by(name: 'No Eggs')
                if dietaryFind.present?
                  gfooditem.dietaries << dietaryFind
                end
              elsif dietary.to_i == 3
                dietaryFind = Dietary.find_by(name: 'Gluten Free')
                if dietaryFind.present?
                  gfooditem.dietaries << dietaryFind
                end
              elsif dietary.to_i == 5
                dietaryFind = Dietary.find_by(name: 'No Fish/Shellfish')
                if dietaryFind.present?
                  gfooditem.dietaries << dietaryFind
                end
              elsif dietary.to_i == 6
                dietaryFind = Dietary.find_by(name: 'No Say')
                if dietaryFind.present?
                  gfooditem.dietaries << dietaryFind
                end
              else dietary.to_i == 7
                dietaryFind = Dietary.find_by(name: 'No Peanuts')
                if dietaryFind.present?
                  gfooditem.dietaries << dietaryFind
                end
              end
            end
          end
          ingredients = row['Type'].to_s.split(',')
          ingredients.each do |ingredient|
            if ingredient.to_i > 0
              if ingredient.to_i == 4
                gfooditem.spicy = 1
                gfooditem.save!
              elsif ingredient.to_i == 6
                gfooditem.best_seller = 1
                gfooditem.save!
              elsif ingredient.to_i == 8
                ingredientFind = Ingredient.find_by(name: 'Chicken')
                if ingredientFind.present?
                  gfooditem.ingredients << ingredientFind
                end
              elsif ingredient.to_i == 9
                ingredientFind = Ingredient.find_by(name: 'Pork')
                if ingredientFind.present?
                  gfooditem.ingredients << ingredientFind
                end
              elsif ingredient.to_i == 11
                ingredientFind = Ingredient.find_by(name: 'Beef')
                if ingredientFind.present?
                  gfooditem.ingredients << ingredientFind
                end
              elsif ingredient.to_i == 12
                ingredientFind = Ingredient.find_by(name: 'Fish')
                if ingredientFind.present?
                  gfooditem.ingredients << ingredientFind
                end
              elsif ingredient.to_i == 13
                ingredientFind = Ingredient.find_by(name: 'Seafood')
                if ingredientFind.present?
                  gfooditem.ingredients << ingredientFind
                end
              else ingredient.to_i == 14
                ingredientFind = Ingredient.find_by(name: 'Eggs')
                if ingredientFind.present?
                  gfooditem.ingredients << ingredientFind
                end
              end
            end
          end
        end
      end
    end

    Restaurant.all.each do |restaurant|
      unless restaurant.gmenus.present?
        restaurant.gmenus.build.save!
      end
    end
  end
end
