class Distance < ApplicationRecord
  validates :lat0, :long0, :lat1, :long1, presence: true
  enum unit: [:miles]

  def self.calculate point1, point2
    return nil if point1.length < 2 || point2.length < 2
    origion = point1.join(", ")
    destination = point2.join(", ")
    record = Distance.where("(lat0 = #{point1[0]} OR lat1 = #{point1[0]}) AND (long0 = #{point1[1]} OR long1 = #{point1[1]}) AND (lat0 = #{point2[0]} OR lat1 = #{point2[0]}) AND (long0 = #{point2[1]} OR long1 = #{point2[1]})").last
    if record.present?
      return record.distance.to_f
    else
      url = "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=" \
        "#{origion}&destinations=#{destination}&key=#{ENV['MAP_API_KEY']}"
      response = HTTParty.get(url)
      if response.present? && response["rows"].present?
        distance_obj = response["rows"].first["elements"].first
        if distance_obj["status"] == "ZERO_RESULTS"
          return "Google Return #{distance_obj['status']}"
        else
          value = (distance_obj["distance"]["value"]*0.000621371).round(2)
          Distance.create(lat0: point1[0], long0: point1[1], lat1: point2[0], long1: point2[1], distance: value)
          return value
        end
      else
        return "#{response['status']}: #{response['error_message']}"
      end
    end
  end
end
