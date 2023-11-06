class AddRecurrenceDaysToRecurringSchedulers < ActiveRecord::Migration[5.1]
  def change
    add_column :recurring_schedulers, :recurrence_days, :integer
    RecurringScheduler.update_all(recurrence_days: 30)
  end
end
