json.addresses do
  json.array! current_member.company.addresses.active do |address|
    json.(
      address,
      :id, :formatted_address, :address_name, :delivery_instructions
    )
  end
end
