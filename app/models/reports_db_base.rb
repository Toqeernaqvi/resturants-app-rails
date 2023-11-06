class ReportsDbBase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection REPORTS_DB
end