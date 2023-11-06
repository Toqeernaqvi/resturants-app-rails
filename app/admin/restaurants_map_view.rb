ActiveAdmin.register_page "Restaurants Map view" do
  menu false

  content do
    render partial: '/active_admin/restaurants/map'
  end

end
