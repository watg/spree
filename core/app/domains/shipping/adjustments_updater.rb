module Shipping
  # updates adjustments on shipping rates
  class AdjustmentsUpdater
    attr_accessor :shipping_rates

    def initialize(shipping_rates)
      @shipping_rates = shipping_rates
    end

    def update
      shipping_rates.each do |shipping_rate|
        shipping_rate_adjustments(shipping_rate).map(&:update!)
      end
    end

    private

    def shipping_rate_adjustments(shipping_rate)
      Adjustments::Selector.new(shipping_rate.adjustments).additional
    end
  end
end
