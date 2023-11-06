class RepSatisfaction < ApplicationRecord
  def self.populate_rep_satisfactions
    last_inserted_dated_on = RepSatisfaction.last&.dated_on
    where_str = "1=1"
    where_str += " AND dated_on > '#{last_inserted_dated_on}'" unless last_inserted_dated_on.blank?
    records = RepSatisfaction.find_by_sql("SELECT * FROM view_rep_satisfactions WHERE #{where_str} ORDER BY dated_on ASC")
    RepSatisfaction.import(records) unless records.blank?
  end
end