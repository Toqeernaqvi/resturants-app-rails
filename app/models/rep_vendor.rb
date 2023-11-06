class RepVendor < ApplicationRecord
  def self.populate_rep_vendors
    last_inserted_dated_on = RepVendor.last&.dated_on
    where_str = "1=1"
    where_str += " AND dated_on > '#{last_inserted_dated_on}'" unless last_inserted_dated_on.blank?
    records = RepVendor.find_by_sql("SELECT * FROM view_rep_vendors WHERE #{where_str} ORDER BY dated_on ASC")
    RepVendor.import(records) unless records.blank?
  end
end