json.companies_childs_list do
  json.array!(@companies_list) do |company_child|
    json.value company_child.id
    if company_child.class.name == "Address"
      json.label "#{company_child.street_number} "+ company_child.street.to_s
      json.disabled true
      json.company_id company_child.addressable_id
    else
      json.label company_child.name
    end
  end
end