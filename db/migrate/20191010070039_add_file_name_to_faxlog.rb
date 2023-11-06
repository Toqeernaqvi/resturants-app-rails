class AddFileNameToFaxlog < ActiveRecord::Migration[5.1]
  def change
  	add_column :faxlogs, :file_name, :string
  end
end
