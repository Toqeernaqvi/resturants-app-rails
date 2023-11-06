# class S3UploadJob < ApplicationJob
#   queue_as :s3_upload

#   def perform(key, bucket, uniq_time_stamp, dir_type)
#     s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
#     s3_obj = s3.bucket(bucket).object(key)
#     if dir_type == "label"
#       labels_save_path = Rails.root.join('public','ordersummary', uniq_time_stamp + '.docx')
#       File.open(labels_save_path, 'rb') do |file|
#         s3_obj.put(body: file, acl: 'public-read')
#       end
#       puts "Label maker labels file saved to s3 at #{Time.current}"
#       File.delete(labels_save_path) if File.exist?(labels_save_path)
#     elsif dir_type == "pdf"
#       save_path = Rails.root.join('public/download_pdfs', uniq_time_stamp + '.pdf')
#       File.open(save_path, 'rb') do |file|
#         s3_obj.put(body: file, acl: 'public-read')
#       end
#       puts "Summary pdf file saved to s3 at #{Time.current}"
#       File.delete(save_path) if File.exist?(save_path)
#     elsif dir_type == "ordersummary"
#       summary_save_path = Rails.root.join('public/ordersummary', uniq_time_stamp + '.pdf')
#       File.open(summary_save_path, 'rb') do |file|
#         s3_obj.put(body: file, acl: 'public-read')
#       end
#       puts "Order Summary pdf file saved to s3 at #{Time.current}"
#       # File.delete(summary_save_path) if File.exist?(summary_save_path)
#     else
#     end
#   end
# end