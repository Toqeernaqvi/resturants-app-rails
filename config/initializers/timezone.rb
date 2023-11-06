Timezone::Lookup.config(:google) do |c|
  c.api_key = ENV['MAP_API_KEY']
end