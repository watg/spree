module Shipping
  class KitAndPatternMailer
    attr_reader :order

    def initialize(order)
      @order = order.extend(Order::ProductFilter)
    end

    def perform
      if order.contains_pattern_or_kit?
        Spree::ShipmentMailer
        	.kit_and_pattern_survey_email(order)
        	.deliver
      end
    end
  end
end
