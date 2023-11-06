ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do
    # div class: "blank_slate_container", id: "dashboard_default_message" do
    #   span class: "blank_slate" do
    #     span I18n.t("active_admin.dashboard_welcome.welcome")
    #     small I18n.t("active_admin.dashboard_welcome.call_to_action")
    #   end
    # end
    # section "Recently updated content" do
    #   table_for PaperTrail::Version.order('id desc').limit(20) do # Use PaperTrail::Version if this throws an error
    #     column ("Item") { |v| v.item }
    #     # column ("Item") { |v| link_to v.item, [:admin, v.item] } # Uncomment to display as link
    #     column ("Type") { |v| v.item_type.underscore.humanize }
    #     column ("Event") { |v| v.event }
    #     column ("Change Set") { |v| v.changeset }
    #     column ("Modified at") { |v| v.created_at.to_s :long }
    #     # column ("Admin") { |v| link_to AdminUser.find(v.whodunnit).email, [:admin, AdminUser.find(v.whodunnit)] }
    #   end
    # end

    # Here is an example of a simple dashboard with columns and panels.
    #
    # columns do
    #   column do
    #     panel "Recent Posts" do
    #       ul do
    #         Post.recent(5).map do |post|
    #           li link_to(post.title, admin_post_path(post))
    #         end
    #       end
    #     end
    #   end

    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    # end

    # columns do
    #   column do
    #     panel "Restaurants fall in each cuisine" do
    #       data = Cuisine.active.all.uniq.map { |c| [c.name, CuisinesRestaurant.joins(:restaurant).where('cuisines_restaurants.cuisine_id = ? AND restaurants.status = ?', c.id, Restaurant.statuses[:active]).count]}
    #       x_values = data.map(&:last)
    #       x_range = ((x_values.min)..(x_values.max)).to_a
    #       column_chart data, max: x_range.last #, width: '50%', library: {tooltips: {enabled: false}}
    #     end
    #   end
    # end

    # columns do
    #   column do
    #     reports_data = ReportsDbBase.connection.execute("SELECT * from dashboard_metrics ORDER BY CASE WHEN metric_type = 4 THEN 1 ELSE 0 END DESC ")
    #     panel  DashboardMetric.metric_types.keys[reports_data.first['metric_type']] do
    #       column_chart DashboardMetric.data_array(reports_data.first['data']).first['data'], max: DashboardMetric.data_array(reports_data.first['data']).first['x_range'] #, width: '50%', library: {tooltips: {enabled: false}}
    #     end
    #     panel "", class: "metrics_" do
    #       reports_data.each_with_index do |d, index|
    #         if index != 0
    #           render 'metrics_table', d: d unless DashboardMetric.data_array(d['data']).blank?
    #         end
    #       end
    #     end
    #   end
    # end
    if Rails.env.production?
      payload = {
        :resource => {:dashboard => 9},
        :params => {},
        :exp => Time.current.to_i + (60 * 10) # 10 minute expiration
      }
      token = JWT.encode payload, ENV["METABASE_SECRET_KEY"]

      iframe_url = ENV["METABASE_SITE_URL"] + "/embed/dashboard/" + token + "#bordered=true&titled=false"
      render partial: 'active_admin/dashboard/reports', locals: {iframe_url: iframe_url}
    end
  end # content
end
