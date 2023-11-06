class AddSummaryLabelsToRunningmenuAddress < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses_runningmenus, :summary_pdf, :string
    add_column :addresses_runningmenus, :summary_labels, :string
  end
end
