class RepNutrition < ApplicationRecord
  def self.populate_rep_nutritions
    records = RepNutrition.find_by_sql("SELECT * FROM view_rep_nutritions")
    records.each do |record|
      obj = RepNutrition.find_or_initialize_by({name: record.name, dietary_id: record.dietary_id, company_id: record.company_id, address_id: record.address_id, user_id: record.user_id})
      obj.save
    end
  end
end