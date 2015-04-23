module Shipping
  class KnittingExperienceMailer
    attr_reader :order

    def initialize(order)
      @order = order.extend(Order::ProductFilter)
    end

    def perform
      if order.contains_kit? || order.contains_pattern?
        Spree::ShipmentMailer
        	.knitting_experience_survey_email(order)
        	.deliver
      end
    end
  end
end
