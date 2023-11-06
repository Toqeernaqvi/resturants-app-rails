class Rating < ApplicationRecord
  belongs_to :ratingable, polymorphic: true
  belongs_to :user
  belongs_to :runningmenu, optional: true
  belongs_to :order, optional: true
  belongs_to :user
  belongs_to :restaurant, optional: true
  belongs_to :restaurant_address, optional: true

  enum status: [:active, :deleted]
  enum parent_status: [:active, :deleted], _prefix: :parent_status

  after_save :after_save_rating

  def after_save_rating
    update_status if self.saved_change_to_parent_status?
    set_rating if self.saved_change_to_rating_value?
  end

  def update_status
    if self.parent_status_active?
      self.active!
    else
      self.deleted!
    end
    set_rating if self.ratingable_type != 'Address'
  end

  def rating
    rating_value
  end

  def item_type
    if self.ratingable_type == 'Address'
      "Restaurant"
    elsif self.ratingable_type == 'Runningmenu'
      "Services"
    else
      self.ratingable_type
    end
  end

  def item_name
    if self.ratingable_type == 'Runningmenu'
      self.ratingable.runningmenu_name
    elsif self.ratingable_type == 'Fooditem'
      self.ratingable.name
    end
  end

  def restaurant_name
    if self.ratingable_type == 'Address'
      self.ratingable.addressable.name
    elsif self.ratingable_type == 'Fooditem'
      self.restaurant.name
    end
  end

  def restaurant_location
    if self.ratingable_type == 'Address'
      self.ratingable.address_line
    elsif self.ratingable_type == 'Fooditem'
      self.restaurant_address.address_line
    end
  end

  def rated_at
    self.created_at
  end

  def send_rating_email
    email = OrderMailer.order_rating(self.ratingable, self)
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
    if self.ratingable_type == 'Fooditem'
      self.ratingable.menu.address.admins.each do |restaurant_admin|
        email = OrderMailer.vendor_order_rating(self.ratingable, self, restaurant_admin)
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      end
    end
  end

  def set_rating
    self.ratingable.rating_total = self.ratingable.ratings.active.sum(:rating_value)
    self.ratingable.rating_count = self.ratingable.ratings.active.count
    self.ratingable.average_rating = self.ratingable.rating_total / self.ratingable.rating_count
    self.ratingable.save(validate: false)
    if self.ratingable_type == 'Fooditem'
      restaurant_address.rating_total = restaurant_address.ratings.active.sum(:rating_value)
      restaurant_address.rating_count = restaurant_address.ratings.active.count
      restaurant_address.average_rating = restaurant_address.rating_total/restaurant_address.rating_count if restaurant_address.rating_count > 0
      restaurant_address.save(validate: false)

      restaurant.rating_total = restaurant.ratings.active.sum(:rating_value)
      restaurant.rating_count = restaurant.ratings.active.count
      restaurant.average_rating = restaurant.rating_total/restaurant.rating_count if restaurant.rating_count > 0
      restaurant.save(validate: false)
    end
    send_rating_email if self.saved_change_to_rating_value?
  end

  ransacker :rate, formatter: proc {|value|
    results = Rating.where(:ratingable_type=>"Address", :ratingable_id=>RestaurantAddress.where(:addressable_id=>value.to_i).pluck(:id).uniq).pluck(:id)
    # addresses = Rating.where(:ratingable_type=>"Address", :ratingable_id=>RestaurantAddress.where(:addressable_id=>value.to_i).pluck(:id).uniq).pluck(:id)
    # runningmenus = Rating.where(:ratingable_type=>"Runningmenu", :ratingable_id=>Runningmenu.joins(:addresses).where("addresses.addressable_id = ?",value.to_i).pluck(:id).uniq).pluck(:id)
    # fooditems = Rating.where(:ratingable_type=>"Fooditem", :ratingable_id=>Fooditem.joins(:menu => :address).where('addresses.addressable_id = ?', value.to_i).pluck(:id).uniq).pluck(:id)
    # results = addresses | runningmenus | fooditems
    results = results.present? ? results.uniq : nil
   } do |parent|
    parent.table[:id]
  end

end
