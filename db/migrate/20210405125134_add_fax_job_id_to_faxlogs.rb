class AddFaxJobIdToFaxlogs < ActiveRecord::Migration[5.1]
  def change
    add_column :faxlogs, :fax_job_id, :string
  end
end
