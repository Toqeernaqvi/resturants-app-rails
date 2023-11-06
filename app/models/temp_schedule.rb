class TempSchedule < ApplicationRecord

  belongs_to :user, optional: true
  belongs_to :address

  def set_dates
    activation_time = Time.current
    # if self.delivery_at.to_date.monday?
    #   cutoff_at = self.delivery_at.midnight - 3.days + 14.hours
    #   admin_cutoff_at = self.delivery_at.midnight - 3.days + 14.hours
    # elsif self.menu_type == 1 || self.delivery_at.to_date.sunday?
    #   cutoff_at = self.delivery_at.midnight - 2.days + 14.hours
    #   admin_cutoff_at = self.delivery_at.midnight - 2.days + 14.hours
    # else
    #   cutoff_at = self.delivery_at.midnight - 1.days + 14.hours
    #   admin_cutoff_at = self.delivery_at.midnight - 1.days + 14.hours
    # end
    # [self.delivery_at, activation_time, cutoff_at, admin_cutoff_at]
    [self.delivery_at, activation_time, self.cutoff_at, self.admin_cutoff_at]
  end

end
