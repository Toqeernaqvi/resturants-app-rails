class RestaurantAddress < Address
  default_scope -> { where(addressable_type: 'Restaurant') }
  
  searchkick merge_mappings: true, mappings: {
    properties: {
      location: {
        type: "geo_shape",
        strategy: "recursive"
      },
      holidays: {
        properties: {
          start_date: {
            type: "date",
            format: "yyyy-MM-dd"
          },
          end_date: {
            type: "date",
            format: "yyyy-MM-dd"
          }
        }
      },
      monday_shifts: {
        properties: {
          end_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          },
          start_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          }
        }
      },
      tuesday_shifts: {
        properties: {
          end_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          },
          start_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          }
        }
      },
      wednesday_shifts: {
        properties: {
          end_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          },
          start_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          }
        }
      },
      thursday_shifts: {
        properties: {
          end_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          },
          start_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          }
        }
      },
      friday_shifts: {
        properties: {
          end_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          },
          start_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          }
        }
      },
      saturday_shifts: {
        properties: {
          end_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          },
          start_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          }
        }
      },
      sunday_shifts: {
        properties: {
          end_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          },
          start_time: {
            type: "date"
            # ,
            # format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"#"hour_minute"
          }
        }
      }
    }
  }#, word_start: [:name, :cuisine_name, :section_name, :fooditem_name, :dietary_name, :ingredient_name]
  # scope :search_import, -> { where(status: :active) } #, enable_marketplace: true

  # scope :search_import, -> { includes(:menus, :sections, :fooditems, :dietaries, :ingredients, :sunday_shifts, :cuisines, restaurant: [:cuisines]) }
  scope :search_import, -> { includes(:sunday_shifts, menus: [:sections, fooditems: [:dietaries, :ingredients]], restaurant: [:cuisines]) }

  has_many :invoices
  has_many :drivers
  belongs_to :restaurant, foreign_key: 'addressable_id', optional: true
  # enum status: [:approved, :pending, :cancelled]
  # after_save :set_pending_status
  #
  # def set_pending_status
  #   self.status = RestaurantAddress.statuses[:pending]
  # end

  # def should_index?
  #   [status, enable_marketplace] # only index active records
  # end

  has_many :cuisines, through: :restaurant
  has_many :sections, -> {where "sections.status = #{Section.statuses[:active]} AND menus.status = #{Menu.statuses[:active]}"}, through: :menus
  has_many :fooditems, -> {where "fooditems.status = #{Fooditem.statuses[:active]} AND menus.status = #{Menu.statuses[:active]}"}, through: :menus
  has_many :dietaries, -> {where "dietaries.status = #{Dietary.statuses[:active]}"}, through: :fooditems
  has_many :ingredients, -> {where "ingredients.status = #{Ingredient.statuses[:active]}"}, through: :fooditems


  def self.random_images(id, menu_type)
    res = RestaurantAddress.find(id)
    images = res.fooditems.active.where("fooditems.image IS NOT NULL AND menus.menu_type = ?", Menu.menu_types[menu_type]).order("RANDOM()").first(6).collect{|i| i.image.url(:medium)}
    images = [res.logo.url(:medium)]+images
  end
  
  def hours(day)
    hours = []
    self.instance_eval("#{day.downcase}_shifts").each do |shift|
      if shift.start_time.present? && shift.end_time.present?
        hours.push("#{shift.start_time.strftime('%H:%M')} to #{shift.end_time.strftime('%H:%M')}")
      end
    end
    hours.count > 0 ? hours.join(", ") : ""
    # opening_hours = [self.instance_eval("#{day.downcase}_first_start_time")&.strftime('%H:%M'), self.instance_eval("#{day.downcase}_first_end_time")&.strftime('%H:%M')]
    # closing_hours = [self.instance_eval("#{day.downcase}_second_start_time")&.strftime('%H:%M'), self.instance_eval("#{day.downcase}_second_end_time")&.strftime('%H:%M')]
    # opening_hours, closing_hours = opening_hours.compact, closing_hours.compact
    # opening_hours = opening_hours.count > 1 ? opening_hours.join(" to ") : opening_hours.join("")
    # closing_hours = closing_hours.count > 1 ? closing_hours.join(" to ") : closing_hours.join("")
    # arr = [opening_hours, closing_hours].reject(&:empty?)
    # arr.count > 1 ? arr.join(", ") : arr.join("")
  end

  def self.query(search_params, select_fields = nil)
    must_query =  []
    # should_query = [{
    #   "distance_feature": {
    #     "field": "location",
    #     "pivot": "10mi",
    #     "origin": [search_params[:long], search_params[:lat]]
    #   }
    # }]
    must_query << { term: { "enable_marketplace": true } }
    must_query << { term: { "enable_self_service": search_params[:enable_self_service] } }
    must_query << { term: { "status": "active" } }
    must_query << { term: { "restaurant.status": "active" } }
    # binding.pry
    time_between_shift_exists = {
          "script": {
            "script": {
              "source": """
                for (int i=0; i< doc['holidays.id'].length; i++) {
                  ZonedDateTime delivery_at = ZonedDateTime.parse(params.my_input_delivery_date);
                  if( (doc['holidays.start_date'][i].isEqual(delivery_at) || doc['holidays.end_date'][i].isEqual(delivery_at)) || (doc['holidays.start_date'][i].isBefore(delivery_at) && delivery_at.isBefore(doc['holidays.end_date'][i])) ){
                    return false;
                  }
                }

                for (int i=0; i< doc['#{search_params[:day]}_shifts.id'].length; i++) {
                  ZonedDateTime start_time = doc['#{search_params[:day]}_shifts.start_time'][i];
                  ZonedDateTime zstart_time = start_time.withZoneSameInstant(ZoneId.of('#{search_params[:time_zone]}'));
                  int zstart_hour = zstart_time.getHour();
                  int zstart_minute = zstart_time.getMinute();
                  int zstart_total_minutes = zstart_hour * 60 + zstart_minute;
                  
                  ZonedDateTime end_time = doc['#{search_params[:day]}_shifts.end_time'][i];
                  ZonedDateTime zend_time = end_time.withZoneSameInstant(ZoneId.of('#{search_params[:time_zone]}'));
                  int zend_hour = zend_time.getHour();
                  int zend_minute = zend_time.getMinute();
                  int zend_total_minutes = zend_hour * 60 + zend_minute;
                  int my_input_total_minutes = params.my_input_hour * 60 + params.my_input_minute;

                  ZonedDateTime delivery_at = ZonedDateTime.parse(params.my_input_delivery_at);
                  ZonedDateTime zdelivery_at = delivery_at.withZoneSameInstant(ZoneId.of('#{search_params[:time_zone]}'));

                  ZonedDateTime curr_time = ZonedDateTime.parse(params.my_input_curr_time);
                  ZonedDateTime zcurr_time = curr_time.withZoneSameInstant(ZoneId.of('#{search_params[:time_zone]}'));
                  zcurr_time = zcurr_time.plusHours(doc[params.cutoff_key].value);
                  boolean fallsInCutoffRules = zdelivery_at.isAfter(zcurr_time);
                  
                  if(zstart_total_minutes <= my_input_total_minutes && zend_total_minutes >= my_input_total_minutes && fallsInCutoffRules){
                    return true;
                  }
                }

                return false;

              """,
              "params": {
                "my_input_hour": search_params[:time].split(":")[0].to_i,
                "my_input_minute": search_params[:time].split(":")[1].to_i,
                "my_input_delivery_at": search_params[:delivery_at].in_time_zone(search_params[:time_zone]),
                "my_input_delivery_date": search_params[:delivery_at].in_time_zone(search_params[:time_zone]).to_date.to_datetime,
                "my_input_curr_time": Time.current,
                "cutoff_key": search_params[:menu_type] == 'buffet' ? 'buffet_cutoff' : 'individual_meals_cutoff',
                "ss_enabled": search_params[:enable_self_service]
              }
            }
          }
        }
    must_query << time_between_shift_exists
    # && zdelivery_at.isAfter(zcurr_time)
    # must_query << { script: { script: { lang: "expression", inline: "doc['sunday_shifts.start_time'].value > doc['sunday_shifts.end_time'].value" } } }
    # must_query << { script: { script: "doc['monday_shifts.start_time'].value.getHour()*60+doc['monday_shifts.start_time'].value.getMinute() <= 200 && doc['monday_shifts.end_time'].value.getHour()*60+doc['monday_shifts.end_time'].value.getMinute() >= 500 " } }
    # must_query << { script: { script: "ZonedDateTime zstart_time = doc['monday_shifts.start_time'].value;int zstart_hour = zstart_time.getHour();int zstart_minute = zstart_time.getMinute();int zstart_total_minutes = zstart_hour * 60 + zstart_minute;ZonedDateTime zend_time = doc['monday_shifts.end_time'].value;int zend_hour = zend_time.getHour();int zend_minute = zend_time.getMinute();int zend_total_minutes = zend_hour * 60 + zend_minute;int my_input_total_minutes = 2 * 60 + 0;if(zstart_total_minutes <= my_input_total_minutes && zend_total_minutes >= my_input_total_minutes){return true;}return false;" } }
    # must_query << { script: { script: "doc['sunday_shifts.start_time'].date.hourOfDay <= 10 >= doc['sunday_shifts.end_time'].date.hourOfDay" } }
    # must_query << {script: { script: "#{search_params[:day]}_shifts['start_time'].value >= #{search_params[:time]} <= #{search_params[:day]}_shifts['end_time'].value" } }
    # must_query << { range: { "#{search_params[:day]}_shifts.start_time" => { lte: search_params[:time] } } }
    # must_query << { range: { "#{search_params[:day]}_shifts.end_time" => { gte: search_params[:time] } } }
    unless search_params[:menu_type].blank?
      must_query << { term: { "menus.menu_type": search_params[:menu_type] } }
    end
    if search_params[:keyword] && search_params[:keyword].downcase == 'spicy'
      must_query << { term: { "fooditems.spicy": 1 } }
      search_params[:keyword] = ""
    end
    unless search_params[:keyword].blank?
      keyword = search_params[:keyword]
      must_query << { multi_match: {query: keyword, type: "cross_fields", operator: "and", fields: ["restaurant.name.analyzed", "cuisines.name.analyzed", "sections.name.analyzed", "sections.description.analyzed", "fooditems.name.analyzed", "fooditems.description.analyzed", "dietaries.name.analyzed", "ingredients.name.analyzed"]} }
      # must_query << { multi_match: {query: keyword, type: "cross_fields", analyzer: "standard", operator: "and", fields: ["restaurant.name.analyzed", "cuisines.name.analyzed", "sections.name.analyzed", "sections.description.analyzed", "fooditems.name.analyzed", "fooditems.description.analyzed", "dietaries.name.analyzed", "ingredients.name.analyzed"]} }
      # must_query << { more_like_this: { like: keyword, min_doc_freq: 1, min_term_freq: 1, analyzer: "searchkick_search", fields: ["restaurant.name.analyzed", "cuisines.name.analyzed", "sections.name.analyzed", "sections.description.analyzed", "fooditems.name.analyzed", "fooditems.description.analyzed", "dietaries.name.analyzed", "ingredients.name.analyzed"] } }
    end
    # self.search body: { from: 0, size: 100, query: { bool: { must: must_query } } }, load: false
    sort_by = [{discount_percentage: :desc}, {average_rating: :desc}]
    if search_params[:order_by].present? && search_params[:order_by] == "price"
      sort_type = search_params[:order_type].present? ? search_params[:order_type] : "ASC"
      sort_by = [{"#{search_params[:menu_type]}_avg": sort_type}]
    end
    if search_params[:order_by].present? && search_params[:order_by] == "rating"
      sort_type = search_params[:order_type].present? ? search_params[:order_type] : "DESC"
      sort_by = [{average_rating: sort_type}]
    end
    self.search body: { from: 0, size: 100, query: { bool: { must: must_query, filter: {geo_shape: {location: {shape: {type: "point", coordinates: [search_params[:long], search_params[:lat]]}, relation: "intersects"}}}, must_not: [{terms: {id: search_params[:ban_ids]}}] } }, sort: sort_by }, load: false
    # self.search body: { from: 0, size: 100, query: { bool: { must: must_query, must_not: [{terms: {id: search_params[:ban_ids]}}] } }, sort: sort_by }, load: false
  end

  def search_data
    data = self.as_json(
      only: [:id, :discount_percentage, :average_rating, :rating_count, :random_menu_images, :enable_marketplace, :enable_self_service, :individual_meals_cutoff, :buffet_cutoff, :status]
    )
    menus = self.menus.active.as_json(
      only: [:id, :menu_type, :status]
    )
    restaurant = self.restaurant.as_json(
      only: [:id, :name, :status]
    )
    cuisines = self.cuisines.as_json(
      only: [:id, :name]
    )
    sections = self.sections.as_json(
      only: [:id, :name, :description]
    )
    dietaries = self.dietaries.uniq.as_json(
      only: [:id, :name]
    )
    ingredients = self.ingredients.uniq.as_json(
      only: [:id, :name]
    )
    holidays = self.holidays.uniq.as_json(
      only: [:id, :start_date, :end_date]
    )
    fooditems = self.fooditems.active.select("fooditems.id, fooditems.name, fooditems.description, menus.menu_type, fooditems.spicy, fooditems.price, fooditems.skip_markup").collect{|f| {id: f.id, name: f.name, description: f.description, menu_type: f.menu_type, spicy: f.spicy, price: f.price, skip_markup: f.skip_markup}}
    prices_arr = fooditems.map{|key| key[:price] if key[:menu_type] == Menu.menu_types[:breakfast] && key[:price] > 0}.compact
    breakfast_avg = prices_arr.size > 0 ? prices_arr.sum/prices_arr.size : 0

    prices_arr = fooditems.map{|key| key[:price] if key[:menu_type] == Menu.menu_types[:lunch] && key[:price] > 0}.compact
    lunch_avg = prices_arr.size > 0 ? prices_arr.sum/prices_arr.size : 0

    prices_arr = fooditems.map{|key| key[:price] if key[:menu_type] == Menu.menu_types[:dinner] && key[:price] > 0}.compact
    dinner_avg = prices_arr.size > 0 ? prices_arr.sum/prices_arr.size : 0

    prices_arr = self.fooditems.active.where("menus.menu_type = ?", Menu.menu_types[:buffet]).joins(:dishsize_fooditems).select("dishsize_fooditems.price").map{|key| key[:price] if key[:price] > 0}.compact
    buffet_avg = prices_arr.size > 0 ? prices_arr.sum/prices_arr.size : 0
    
    images = self.images&.collect{|i| i.image.url(:medium) }
    images = [self.logo.url(:medium)]+images
    shifts = self.restaurant_shifts.where("closed = ?", false).group_by{|s| s.label}

    monday_shifts = shifts["Monday"]&.collect{|s| {id: s.id, start_time: s.start_time.utc, end_time: s.end_time.utc } }
    tuesday_shifts = shifts["Tuesday"]&.collect{|s| {id: s.id, start_time: s.start_time.utc, end_time: s.end_time.utc } }
    wednesday_shifts = shifts["Wednesday"]&.collect{|s| {id: s.id, start_time: s.start_time.utc, end_time: s.end_time.utc } }
    thursday_shifts = shifts["Thursday"]&.collect{|s| {id: s.id, start_time: s.start_time.utc, end_time: s.end_time.utc } }
    friday_shifts = shifts["Friday"]&.collect{|s| {id: s.id, start_time: s.start_time.utc, end_time: s.end_time.utc } }
    saturday_shifts = shifts["Saturday"]&.collect{|s| {id: s.id, start_time: s.start_time.utc, end_time: s.end_time.utc } }
    sunday_shifts = shifts["Sunday"]&.collect{|s| {id: s.id, start_time: s.start_time.utc, end_time: s.end_time.utc } }

    data.merge(menus: menus, restaurant: restaurant, cuisines: cuisines, sections: sections, fooditems: fooditems, dietaries: dietaries, ingredients: ingredients, lunch_avg: lunch_avg, breakfast_avg: breakfast_avg, dinner_avg: dinner_avg, buffet_avg: buffet_avg, monday_shifts: monday_shifts, tuesday_shifts: tuesday_shifts, wednesday_shifts: wednesday_shifts, thursday_shifts: thursday_shifts, friday_shifts: friday_shifts, saturday_shifts: saturday_shifts, sunday_shifts: sunday_shifts, holidays: holidays, images: images, location: {type: "circle", coordinates: [longitude, latitude], radius: "#{self.enable_self_service ? self.delivery_radius : 20 }miles" } )
  end

end
