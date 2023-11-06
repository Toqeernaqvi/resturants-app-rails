ActiveAdmin.register PaymentLog do
  #menu priority: 10
  menu parent: 'Logs'
  config.clear_action_items!
  config.batch_actions = false
  actions :all, :except => [:new, :create, :edit, :destroy ]

  permit_params do
    permitted = [:refund_amount, :refund_date, :refund_by, :status]
  end

  index do
    column :id
    column :user do |p|
      if p.user.present?
        p.user
      else
        share_meeting = ShareMeeting.find_by_email(p.email)
        share_meeting.name if share_meeting.present?
      end
    end
    column :email
    column :company
    column :payment_gateway
    column :order do |payment_log|
      order_id = payment_log.orders.last.id
      link_to "#{order_id}", admin_order_path("#{order_id}"), class: "link_to_class"
    end
    column :amount
    column :status do |p|
      status_tag(:success) if p.success?
      status_tag(:failed) if p.failed?
      status_tag(:refunded) if p.refunded?
    end
    column :message
    column :created_at
    column :updated_at
    actions do |log|
      link_to "Refund", load_refund_admin_payment_log_path(log.id), class: 'member_link', remote: true if log.success? && log.stripe? && (log.user_id.present? || log.email.present?)
    end
  end

  show do
    attributes_table do
      row :id
      row :payment_gateway
      row :user
      row :email
      row :amount
      row :status
      row :refunded_amount
      row :refund_date
      row :refund_by
      row :message
      ol 'Orders List', :class => "wrapper_optionset" do
        render partial: 'line-items', locals: { resource: payment_log }
      end
    end
  end

  member_action :load_refund, method: :get do
    @payment_log = PaymentLog.find(params[:id])
    respond_to do |format|
      format.js { render "load_refund" }
    end
  end

  filter :user_id, label: "User", as: :select, collection: proc{ User.active.map{ |u| [u.name, u.id] } }
  filter :email
  filter :payment_gateway, as: :select, collection: -> {PaymentLog.payment_gateways}
  filter :amount
  filter :status, as: :select, collection: -> {PaymentLog.statuses}
  filter :message
  filter :created_at, as: :date_range
  filter :updated_at, as: :date_range

  controller do
    def update
      resource.refund_amount = params[:payment_log][:refund_amount].to_f
      if resource.valid?
        begin
          result = Stripe::Refund.create({
            charge: resource.transaction_id,
            amount: (resource.refund_amount*100).to_i
          })
          if result.present? && result.status == "succeeded"
            resource.refund_amount = result.amount/100
            resource.refunded_amount += (result.amount.to_f/100.to_f)
            resource.refund_date = Time.current
            resource.refund_by = current_admin_user.id
            resource.status = PaymentLog.statuses[:refunded] if resource.refunded_amount == resource.amount
            if resource.save
              flash[:notice] = "Successfully refunded the transaction"
            else
              flash[:notice] = resource.errors.full_messages.first
            end
          else
            flash[:notice] = result.message
          end
        rescue StandardError => e
          resource.errors.add(:refund_amount, "#{e}")
          render :load_refund
        end
      else
        render :load_refund
      end
    end
  end
end
