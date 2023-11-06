class AddTwoCheckboxToContact < ActiveRecord::Migration[5.1]
  def change
    add_column :contacts, :email_summary_check, :boolean, default: true, after: :fax
    add_column :contacts, :fax_summary_check, :boolean, default: true, after: :fax
    add_column :contacts, :email_label_check, :boolean, default: true, after: :fax
  end
end
