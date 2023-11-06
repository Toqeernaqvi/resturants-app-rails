class RepBox < ApplicationRecord
  def self.populate_rep_boxes
    last_inserted_dated_on = RepBox.last&.dated_on
    where_str = "1=1"
    where_str += " AND dated_on > '#{last_inserted_dated_on}'" unless last_inserted_dated_on.blank?
    records = RepBox.find_by_sql("SELECT * FROM view_rep_boxes WHERE #{where_str} ORDER BY dated_on ASC")
    RepBox.import(records) unless records.blank?
  end
end
