ActiveAdmin.register_page "Menu Preference" do
  menu parent: 'Restaurants', priority: 2

  action_item :cuisines do
    link_to "Cuisines", "/admin/cuisines"
  end

  action_item :ingredients do
    link_to "Ingredients", "/admin/ingredients"
  end

  action_item :dietaries do
    link_to "Dietaries", "/admin/dietaries"
  end
end
