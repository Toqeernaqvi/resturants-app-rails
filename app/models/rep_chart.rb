class RepChart < ApplicationRecord
  def self.populate_rep_charts
    last_inserted_dated_on = RepChart.last&.dated_on
    where_str = "1=1"
    where_str += " AND dated_on > '#{last_inserted_dated_on}'" unless last_inserted_dated_on.blank?
    records = RepChart.find_by_sql("SELECT * FROM view_rep_charts WHERE #{where_str} ORDER BY dated_on ASC")
    RepChart.import(records) unless records.blank?
  end
end
