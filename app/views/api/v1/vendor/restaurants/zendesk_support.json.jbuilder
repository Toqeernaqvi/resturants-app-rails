json.logs do
  json.array!(@freshdesklogs) do |log|
    json.extract! log, :name, :email, :subject, :description, :attachment
  end
  json.array!([1]) do |log|
    json.name current_member.name
    json.email params[:email]
    json.subject params[:subject]
    json.description params[:description]
    json.attachment nil
  end
end