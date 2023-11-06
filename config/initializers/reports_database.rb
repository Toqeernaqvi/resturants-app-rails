REPORTS_DB = YAML::load(ERB.new(File.read(Rails.root.join(ENV['SHARED_CONFIG_PATH'],"reports_database.yml"))).result)[Rails.env]
