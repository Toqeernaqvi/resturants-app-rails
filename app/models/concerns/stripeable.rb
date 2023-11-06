module Stripeable
  extend ActiveSupport::Concern
  included do
    after_save :create_customer, if: lambda { |obj| obj.stripe_token.present? && (obj.stripe_token_changed? || obj.saved_change_to_stripe_token?) }
    after_save :remove_card, if: lambda {|obj| obj.delete_stripe_card.present? && obj.delete_stripe_card }
    
    def create_customer
      customer = Stripe::Customer.create({
        name: self.name,
        email: self.email,
        description: "Customer for #{self.class.name == 'User'? self.company.name : 'ShareMeeting#'+self.id.to_s}",
        source: self.stripe_token
      })
      if customer.present?
        self.update_columns(customer_id: customer.id)
      end
    end

    def charge_customer(order_id)
      order = Order.find order_id
      charge = Stripe::Charge.create({
        amount: (order.user_paid_with_fee * 100).to_i,
        currency: "usd",
        customer: self.customer_id,
      })
      if charge.present? && charge.paid
        refund = order.refund_stripe
        payment_log = PaymentLog.create(company: order.runningmenu.company, user_id: (order.share_meeting.present? ? nil : order.user_id), amount: order.user_paid_with_fee, refund_amount: order.user_paid_with_fee, payment_gateway: PaymentLog.payment_gateways[:stripe], status: PaymentLog.statuses[:success], message: "Transaction successfully processed.", transaction_id: charge.id, email: self.email)
        payment_log.orders << [order]
        order.send_confirmation_email(refund)
      end
    end

    def card_details
      if (self.instance_of?(ShareMeeting))
        return retreive_card(self.stripe_token) if self.stripe_token.present?
      else
        if self.company_admin? && (self.company.billing.present? && self.company.billing.token.present?)
          return retreive_card(self.company.billing.token)
        elsif self.stripe_token.present?
          return retreive_card(self.stripe_token)
        end
      end
    end
    
    def retreive_card token
      card = nil
      details = Stripe::Token.retrieve(
        token
      )
      card = details.card if details.present?
    end

    def remove_card
      if self.stripe_token.present? && self.customer_id.present?
        card_id = retreive_card(self.stripe_token).id
        delete_registered_card(self.customer_id, card_id)  
        self.update_columns(stripe_token: nil, customer_id: nil)
      end
    end

    def delete_registered_card(customer_id, card_id)
        result = Stripe::Customer.delete_source(
            customer_id,
            card_id
          )
    end

    def refund_customer
      begin
        
      rescue Stripe::StripeError => e
        
      rescue => e
        
      end
    end

  end

end