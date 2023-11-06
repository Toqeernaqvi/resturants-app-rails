ActiveAdmin.register_page "Manual Schedulers" do
  menu false

  content do
    if params[:runningmenu_ids].present?
      schedulers = Runningmenu.where(:id=>params[:runningmenu_ids]).order(:delivery_at)
      render partial: 'admin/schedulers/manual_schedulers_list', locals: {schedulers: schedulers}
    else
      render partial: 'admin/invoices/filter_companies', locals: {recurrence_tag: true, url: '/admin/schedulers/recurrence_schedulers', collection: Company.active.joins(:recurring_schedulers).where("recurring_schedulers.status != ?", RecurringScheduler.statuses[:cancelled]).uniq.collect{ |c| [c.name, c.id] }}
    end
  end

end