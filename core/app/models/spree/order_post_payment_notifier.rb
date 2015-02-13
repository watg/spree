module Spree
  class OrderPostPaymentNotifier
    attr_reader :order

    def initialize(order)
      @order = order
    end

    def process
      send_gift_card
      send_digital_pattern
    end

    private

    def send_gift_card
      if order.has_gift_card?
        send_one(:gift_card) do
          Spree::GiftCardJobCreator.new(order).run
        end
      end
    end

    def send_digital_pattern
      if order.some_digital?
        send_one(:digital_download) do
          Spree::DigitalDownloadMailer.delay.send_links(order)
        end
      end
    end

    def send_one(type, &block)
      if Spree::NotificationEmail.where(order: @order, email_type: type).empty?
        Spree::NotificationEmail.create!(order: @order, email_type: type)
        yield
      end
    end
  end
end
