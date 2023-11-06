class RepBudgetAnalysis < ApplicationRecord
  def self.populate_rep_budget_analysis
    last_inserted_dated_on = RepBudgetAnalysis.last&.dated_on
    where_str = "1=1"
    where_str += " AND dated_on > '#{last_inserted_dated_on}'" unless last_inserted_dated_on.blank?
    records = RepBudgetAnalysis.find_by_sql("SELECT * FROM view_rep_budget_analysis WHERE #{where_str} ORDER BY dated_on ASC")
    RepBudgetAnalysis.import(records) unless records.blank?
  end
end
