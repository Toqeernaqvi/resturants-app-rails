json.logs @freshdesklogs do |log|
  json.extract! log, :name, :email, :subject, :description, :attachment
end