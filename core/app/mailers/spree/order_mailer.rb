module Spree
  class OrderMailer < BaseMailer
    def confirm_email(order, resend = false)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "#{Spree::Store.current.name} #{Spree.t('order_mailer.confirm_email.subject')} ##{@order.number}"

      mail(to: @order.email, from: from_address, subject: subject)

      mandrill_default_headers(tags: "order, confirmation", template: "#{I18n.locale}_confirm_email_v2")
      headers['X-MC-MergeVars'] = confirm_data.to_json
    end

    def cancel_email(order, resend = false)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "#{Spree::Store.current.name} #{Spree.t('order_mailer.cancel_email.subject')} ##{@order.number}"
      mail(to: @order.email, from: from_address, subject: subject)

      mandrill_default_headers(tags: "order, cancellation", template: "#{I18n.locale}_cancel_email")
      headers['X-MC-MergeVars'] = cancel_data.to_json
    end

    private

    def order_data
      @order_formatter ||= Spree::OrderFormatter.new(@order)
      @order_formatter.order_data
    end

    def cancel_data
      order_data.merge({})
    end

    def confirm_data
      order_data.merge({})
    end
  end
end
