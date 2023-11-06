class FooditemImageUploadToS3Job < ApplicationJob
  queue_as :upload_to_s3

  def perform(fooditem, file_url)
    begin
      return if file_url.blank?
      fooditem.remote_image_url = file_url
      fooditem.save
    rescue => ex
      Rails.logger.error "[UploadToS3] - #{ex.message}"
    end
  end
  
end