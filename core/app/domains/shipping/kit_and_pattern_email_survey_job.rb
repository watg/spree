module Shipping
  class KitAndPatternEmailSurveyJob
    attr_reader :order

    DELAY = 1.month.from_now

    def initialize(order)
      @order = order.extend(Order::ProductFilter)
    end

    def perform
      if order.contains_pattern_or_kit?
        Spree::ShipmentMailer
        	.kit_and_pattern_survey_email(order)
        	.delay(run_at: DELAY)
        	.deliver
      end
    end
  end
end
