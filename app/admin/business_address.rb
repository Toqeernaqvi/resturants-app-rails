ActiveAdmin.register BusinessAddress, as: "Tools" do
  menu parent: 'Settings'
  config.batch_actions = false
  actions :all, :except => [:new, :create, :destroy, :edit, :update]

  action_item do
    link_to 'Download Sample', download_sample_admin_tools_path, class: 'hideThisElement'
  end

  action_item do
    link_to 'Google Places Lookup', upload_csv_admin_tools_path, class: 'bulk_restaurant', for: 'uploadRestaurantCSV_', remote: true
  end

  collection_action :download_sample, method: :get do
    send_file(
      "#{Rails.root}/app/assets/csvs/sample_google_place_loopup.csv",
      filename: "sample_google_place_loopup.csv",
      type: "text/csv",
      disposition: 'attachment'
    )
  end

  collection_action :upload_csv, method: :post do
    @client = GooglePlaces::Client.new(ENV['MAP_API_KEY'])
    CSV.parse(params[:bulkRestaurantCsv].read, :headers => true) do |row|
      if row.headers.include?('Name')
        if !BusinessAddress.exists?(['name LIKE ?', "%#{row['Name'].gsub(/[^a-zA-Z0-9\-]/," ")}%"])
          result = @client.spots_by_query("#{row['Name'].gsub(/[^a-zA-Z0-9\-]/," ")}", :detail => true, :lat => ENV['CHOWMILL_LAT'].to_f, :lng => ENV['CHOWMILL_LNG'].to_f).first
          if result.present?
            BusinessAddress.find_or_create_by(
              name: result.name,
              rating: result.rating,
              formatted_phone_number: result.formatted_phone_number,
              formatted_address: result.formatted_address,
              vicinity: result.vicinity,
              price_level: result.price_level,
              review_count: result.reviews.count,
              url: result.url,
              website: result.website,
              weekday_text: result.opening_hours.present? ? result.opening_hours["weekday_text"].join(",\n") : "",
              business_type: result.types.join(",\n"),
              lat: result.lat,
              lng: result.lng
            )
          end
        end
      else
        redirect_to admin_tools_path, notice: "Please upload correct format file"
        return
      end
    end
    redirect_to admin_tools_path
    return
  end


  index do
    column :id
    column "Name" do |b|
    link_to b.name, b.url
    end
    column :rating
    column :review_count
    column :formatted_phone_number
    column :formatted_address
    column :vicinity
    column :price_level
    column :website
    column :business_type
    actions
  end

  controller do
    skip_before_action :verify_authenticity_token, :only => [ :upload_csv ]
  end

  filter :price_level
  filter :business_type
  filter :rating
  filter :formatted_address, label: "Address"
  filter :last_import_data, label: "Last imported",  as: :check_boxes, collection: [['', true]]
end
