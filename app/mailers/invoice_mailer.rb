class InvoiceMailer < ApplicationMailer
  def forward_invoice_email(user, scheduler)
    @schedular = scheduler
    @user= user
    mail(to: @user.email, subject: "Your requested invoice for #{@schedular.delivery_at.strftime("%a, %b %d")} Order # #{@schedular.id}")

  end
end