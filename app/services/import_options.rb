class ImportOptions
  def call
    file_path = File.new(Rails.root.join('app/assets/csvs/options.csv'))
    spreadsheet = Roo::Spreadsheet.open(file_path)

    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      restaurant = Restaurant.find_by(vendor_id: row['VendorID'])
      if restaurant.present?
        optionset = restaurant.gmenus.first.goptionsets.find_by(choice_type: row['ChoiceType'])
        if optionset.present?
          goption = optionset.goptions.create(
            description: row['Name'],
            price: row['IncrementalPrice']
          )
          if goption.present?
            dietaries = row['Allergens'].to_s.split(',')
            dietaries.each do |dietary|
              if dietary.to_i > 0
                if dietary.to_i == 2
                  dietaryFind = Dietary.find_by(name: 'No Eggs')
                  if dietaryFind.present?
                    goption.dietaries << dietaryFind
                  end
                elsif dietary.to_i == 3
                  dietaryFind = Dietary.find_by(name: 'Gluten Free')
                  if dietaryFind.present?
                    goption.dietaries << dietaryFind
                  end
                elsif dietary.to_i == 5
                  dietaryFind = Dietary.find_by(name: 'No Fish/Shellfish')
                  if dietaryFind.present?
                    goption.dietaries << dietaryFind
                  end
                elsif dietary.to_i == 6
                  dietaryFind = Dietary.find_by(name: 'No Say')
                  if dietaryFind.present?
                    goption.dietaries << dietaryFind
                  end
                else dietary.to_i == 7
                  dietaryFind = Dietary.find_by(name: 'No Peanuts')
                  if dietaryFind.present?
                    goption.dietaries << dietaryFind
                  end
                end
              end
            end
            ingredients = row['Type'].to_s.split(',')
            ingredients.each do |ingredient|
              if ingredient.to_i > 0
                if ingredient.to_i == 8
                  ingredientFind = Ingredient.find_by(name: 'Chicken')
                  if ingredientFind.present?
                    goption.ingredients << ingredientFind
                  end
                elsif ingredient.to_i == 9
                  ingredientFind = Ingredient.find_by(name: 'Pork')
                  if ingredientFind.present?
                    goption.ingredients << ingredientFind
                  end
                elsif ingredient.to_i == 11
                  ingredientFind = Ingredient.find_by(name: 'Beef')
                  if ingredientFind.present?
                    goption.ingredients << ingredientFind
                  end
                elsif ingredient.to_i == 12
                  ingredientFind = Ingredient.find_by(name: 'Fish')
                  if ingredientFind.present?
                    goption.ingredients << ingredientFind
                  end
                elsif ingredient.to_i == 13
                  ingredientFind = Ingredient.find_by(name: 'Seafood')
                  if ingredientFind.present?
                    goption.ingredients << ingredientFind
                  end
                else ingredient.to_i == 14
                  ingredientFind = Ingredient.find_by(name: 'Eggs')
                  if ingredientFind.present?
                    goption.ingredients << ingredientFind
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
