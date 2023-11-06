ActiveAdmin.register_page "Manual Invoice" do
  menu false

  content do
    if params[:invoice_ids].present?
      invoices = Invoice.where(:id=>params[:invoice_ids])
      render partial: 'admin/invoices/manual_invoices_list', locals: {invoices: invoices}
    else
      render partial: 'admin/invoices/filter_companies', locals: {url: '/admin/invoices/filtered_company', collection: Company.active.joins(:billing).where("billings.disable_auto_invoice is true").collect{ |c| [c.name, c.id] }}
    end
  end

end