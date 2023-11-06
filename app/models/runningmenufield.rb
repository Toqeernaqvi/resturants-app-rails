class Runningmenufield < ApplicationRecord
  # has_paper_trail if: lambda {|o| o.runningmenu.updated_from_frontend }

  belongs_to :runningmenu, optional: true
  belongs_to :recurring_scheduler, optional: true
  belongs_to :field, optional: true
  belongs_to :fieldoption, optional: true

  enum field_type: [:dropdown, :text]
  before_save :initialize_attributes
  # validate :required_fields

  def initialize_attributes
    self.field_type = self.field.field_type unless self.field.blank?
  end

  # def required_fields
  #   if self.field.present? && self.field.required?
  #     if self.field.dropdown? && !self.fieldoption.present?
  #       errors[:field_id] << "#{self.field.company.fields.where(required: 1).pluck(:name).join(', ')} field is required."
  #     elsif self.field.text? && self.value.blank?
  #       errors[:field_id] << "#{self.field.company.fields.where(required: 1).pluck(:name).join(', ')} field is required."
  #     end
  #   end
  # end
end
