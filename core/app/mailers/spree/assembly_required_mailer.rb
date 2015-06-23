module Spree
  class AssemblyRequiredMailer
    attr_accessor :order

    def initialize(order)
      @order = order
    end

    def send
      NotificationMailer.delay.send_notification(
        message,
        Rails.application.config.personalisation_email_list,
        "Customisation Order #" + order.number.to_s
      )
    end

  private
    def message
      StringIO.open do |s|
        s.puts "Hello"
        s.puts "Order <a href='#{order_url}'>##{order.number}</a> contains customisation(s):"
        s.puts "<b>#{products}</b>."
        s.puts "It has been marked as internal"
        s.puts "Thank you."
        s.string
      end
    end

    def products
      order
        .line_items_requiring_assembly
        .map { |li| li.variant.product.name }
        .join(", ")
    end

    def order_url
      Core::Engine
        .routes
        .url_helpers
        .edit_admin_order_url(order)
    end
  end
end
