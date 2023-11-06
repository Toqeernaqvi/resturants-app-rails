class Admin::AcknowledgesController < ApplicationController
  skip_before_action :verify_authenticity_token, except: [:acknowledge, :generate_pdf]

  def acknowledge
    runningmenuaddress = AddressesRunningmenu.find_by(address_id: Base64.decode64(params[:address_id]), runningmenu_id: Base64.decode64(params[:id]))
    if runningmenuaddress.present? && params[:type] == 'receipt' && runningmenuaddress.receipt_acknowledge!
      render :success, locals: {success: true, type: params[:type], cutoff_at: params[:cutoff].to_time.strftime('%A, %B %d, %I:%M%p')}
    elsif runningmenuaddress.present? && params[:type] == 'accept_orders' && runningmenuaddress.orders_acknowledge!
      render :success, locals: {success: true, type: params[:type]}
    elsif runningmenuaddress.present? && params[:type] == 'accept_changes' && runningmenuaddress.changes_acknowledge!
      render :success, locals: {success: true, type: params[:type]}
    else
      render :success, locals: {success: false, type: params[:type]}
    end
  end
end
