module Shipping
  class KnittingExperienceMailer
    def initialize(order)
      @order = order
    end

    def perform
      if order.contains_kit? || order.contains_pattern?
        Spree::ShipmentMailer
        	.knitting_experience_email(order)
        	.deliver
      end
    end

    def order
      @order.extend(Order::ProductFilter)
    end
  end
end
