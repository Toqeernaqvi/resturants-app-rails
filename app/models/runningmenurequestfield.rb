# class Runningmenurequestfield < ApplicationRecord
#   belongs_to :runningmenu_request, optional: true
#   belongs_to :runningmenu, optional: true
#   belongs_to :field, optional: true
#   belongs_to :fieldoption, optional: true

#   enum field_type: [:dropdown, :text]
#   before_save :initialize_attributes

#   def initialize_attributes
#     self.field_type = self.field.field_type
#   end
# end
