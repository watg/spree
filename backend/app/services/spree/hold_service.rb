module Spree
  class HoldService < ActiveInteraction::Base
    include Spree::Core::Engine.routes.url_helpers

    model :order, class: 'Spree::Order'
    model :user, class: Spree.user_class
    string :reason
    string :type

    def execute
      order.transaction do
        order.order_notes.create(reason: reason, user: user)

        case type
        when "warehouse"
          order.warehouse_hold!
          send_email(order, reason)
        when "customer_service"
          order.customer_service_hold!
        else
          raise ArgumentError, "Unknown hold type: #{type}"
        end
      end

    end

    private

    def send_email(order, reason)
      subject = "Order #{order.number} put on hold"
      message = "Order #{order.number} has been put on hold by the warehouse:"
      message << "\n\n#{reason}"
      message << "\n\n#{edit_admin_order_url(order)}"
      message << "\n"
      Spree::NotificationMailer.delay.send_notification(message, email_list, subject)
    end

    def email_list
      Rails.application.config.order_hold_email_list
    end
  end
end
