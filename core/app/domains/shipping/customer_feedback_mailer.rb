module Shipping
  class CustomerFeedbackMailer
    attr_reader :order

    def initialize(order)
      @order = order
    end

    def perform
      Spree::ShipmentMailer.survey_email(order).deliver
    end
  end
end
