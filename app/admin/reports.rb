ActiveAdmin.register_page "Reports" do
  menu priority: 11, label: "Reports"
  config.breadcrumb = false
  content title: "Reports" do
    div id: "reportContainer" do
      ul class: "reportList" do
        li do
          link_to "Orders Not Invoiced", admin_orders_not_invoiced_path
        end
        li do
          link_to "Orders Not Billed", admin_orders_not_billed_path
        end
        li do
          link_to "Average Take Rate", admin_average_take_rate_path
        end
      end
    end
  end
end
