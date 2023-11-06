json.admins @restaurant_admins do |admin|
  json.(
    admin,
    :id, :first_name, :last_name, :email, :phone_number, :fax, :fax_summary_check, :email_summary_check, :email_label_check, :send_text_reminders
  )
end