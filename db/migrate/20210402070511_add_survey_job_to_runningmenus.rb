class AddSurveyJobToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :survey_job_id, :string
  end
end
