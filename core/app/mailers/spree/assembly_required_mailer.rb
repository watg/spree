module Spree
  class AssemblyRequiredMailer
    attr_accessor :order

    def initialize(order)
      @order = order
    end

    def send
      order_url = Core::Engine.routes.url_helpers.edit_admin_order_url(order)
      products = order.line_items_requiring_assembly.map { |li| li.variant.product.name }.join(", ")
      message = "Hello,\n
          Order <a href='#{order_url}'>##{order.number}</a> contains customisation(s):\n
          <b>#{products}</b>.\n
          It has been marked as internal.\n
          Thank you."
      NotificationMailer.delay.send_notification(
        message,
        Rails.application.config.personalisation_email_list,
        "Customisation Order #" + order.number.to_s
      )
    end
  end
end
