class BusinessAddress < ApplicationRecord

  scope :last_imported, -> {
    where("DATE(created_at) = ?",BusinessAddress.maximum('DATE(created_at)')).order(id: :desc)
  }

  ransacker :last_import_data, formatter: proc {|value|
    results = BusinessAddress.last_imported.map(&:id)
    results = results.present? ? results : nil
   } do |parent|
    parent.table[:id]
  end
end
