class AddSiteSurveyToCompanies < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :site_survey, :text
  end
end
