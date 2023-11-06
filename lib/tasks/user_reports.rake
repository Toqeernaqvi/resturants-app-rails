namespace :user_reports do
  desc "Task to create records on rep_boxes"
  task populate_rep_boxes: :environment do
    RepBox.populate_rep_boxes()
  end

  desc "Task to create records on vendors"
  task populate_rep_vendors: :environment do
    RepVendor.populate_rep_vendors()
  end

  desc "Task to create records on budget analysis"
  task populate_rep_budget_analysis: :environment do
    RepBudgetAnalysis.populate_rep_budget_analysis()
  end

  desc "Task to create records on expense saving charts"
  task populate_rep_charts: :environment do
    RepChart.populate_rep_charts()
  end
  
  desc "Task to create records on nutritions"
  task populate_rep_nutritions: :environment do
    RepNutrition.populate_rep_nutritions()
  end
  
  desc "Task to create records on nutritions"
  task populate_rep_satisfactions: :environment do
    RepSatisfaction.populate_rep_satisfactions()
  end
end
