class ReportMailer < ApplicationMailer

  def orders_not_invoiced(orders, user, error = nil)
    @error = error
    @orders = orders
    @user = user
    mail(to: user.email, subject: "Orders not billed in any invoice")
  end

  def orders_not_billed(orders, user, error = nil)
    @error = error
    @orders = orders
    @user = user
    mail(to: user.email, subject: "Orders not billed in any restaurant billing")
  end

  def average_take_rate(orders, user, error = nil)
    @error = error
    @orders = orders
    @user = user
    mail(to: user.email, subject: "Average Take Rate Report")
  end
end
