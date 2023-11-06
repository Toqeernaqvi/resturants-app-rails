json.total_pages @runningmenus.total_pages
json.per_page @per_page
json.sort_by @sort_by
json.sort_order @sort_order
json.s3_base_url "https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com"
json.runningmenus @runningmenus