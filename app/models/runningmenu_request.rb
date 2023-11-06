# class RunningmenuRequest < ApplicationRecord
#   acts_as_paranoid

#   belongs_to :address
#   belongs_to :company, optional: true
#   enum runningmenu_request_type: [:lunch, :dinner, :breakfast]
#   enum status: [:active, :deleted]
#   before_create :add_company
#   # not in use
#   # after_create :create_scheduler, unless: lambda{|c| c.schedular_check?}
#   before_save :check_recurring
#   has_many :cuisines_requests, dependent: :destroy
#   has_many :cuisines, through: :cuisines_requests
#   accepts_nested_attributes_for :cuisines_requests, allow_destroy: true
#   belongs_to :user
#   #has_many :runningmenus
#   has_many :runningmenurequestfields
#   accepts_nested_attributes_for :runningmenurequestfields, allow_destroy: true
#   enum menu_type: [:individual, :buffet]
#   before_save :set_runnningmenurequest_time

#   def set_runnningmenurequest_time
#     time = self.end_time.strftime "%H:%M:%S"
#     splittedtime = time.split(':')
#     self.delivery_at = self.delivery_at.to_date.at_beginning_of_day.beginning_of_day + splittedtime[0].to_i.hours + splittedtime[1].to_i.minutes + splittedtime[2].to_i.seconds
#   end

#   def add_company
#     self.company_id = self.address.addressable.id
#   end

#   def create_scheduler
#     unless self.recurring?
#       menu = self.runningmenus.create(
#         runningmenu_type: self.runningmenu_request_type,
#         address_id: self.address_id,
#         company_id: self.company_id,
#         delivery_at: self.delivery_at,
#         activation_at: Time.current,
#         cutoff_at: self.delivery_at.midnight - 1.days + 18.hours,
#         admin_cutoff_at: self.delivery_at.midnight + 10.hours,
#         orders_count: self.orders,
#         menu_type: self.menu_type,
#         special_request: self.special_request,
#         status: :pending
#       )

#       self.save!
#       menu.cuisines << self.cuisines if self.cuisines.present?
#       menu.save!
#     else
#       time = self.end_time.strftime "%H:%M:%S"
#       splittedtime = time.split(':')
#       days_into_week = [:monday, :tuesday, :wednesday, :thursday, :friday]
#       (0..3).each do |counter|
#         [self.monday, self.tuesday, self.wednesday, self.thursday, self.friday].each_with_index do |val, index|
#           if val != 0
#             next_date = self.delivery_at.beginning_of_week + (((counter*7)+index)+7).days
#             if self.runningmenu_request_type == 'breakfast'
#               next_date += self.end_time + splittedtime[0].to_i.hours + splittedtime[1].to_i.minutes + splittedtime[2].to_i.seconds
#               admin_cutoff_at =  next_date - 1.day + 10.hours
#               cutoff_at = next_date - 1.day + 10.hours
#             elsif self.runningmenu_request_type == 'lunch'
#               next_date += self.end_time + splittedtime[0].to_i.hours + splittedtime[1].to_i.minutes + splittedtime[2].to_i.seconds
#               admin_cutoff_at =  next_date - 2.hours
#               cutoff_at = next_date  - 1.day + 6.hours
#             else
#               next_date += self.end_time + splittedtime[0].to_i.hours + splittedtime[1].to_i.minutes + splittedtime[2].to_i.seconds
#               admin_cutoff_at =  next_date - 6.hours
#               cutoff_at = next_date - 8.hours
#             end
#             self.runningmenus.create(
#               runningmenu_type: self.runningmenu_request_type,
#               company_id: self.company_id,
#               address_id: self.address_id,
#               delivery_at: next_date,
#               activation_at: Time.current,
#               cutoff_at: cutoff_at,
#               admin_cutoff_at: admin_cutoff_at,
#               status: :pending
#             )
#           end
#         end
#       end
#     end
#   end

#   def check_recurring
#     unless self.recurring?
#       self.monday = 0
#       self.tuesday = 0
#       self.wednesday = 0
#       self.thursday = 0
#       self.friday = 0
#     end
#   end
# end
