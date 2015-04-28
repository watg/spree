module ShippingRates
  class Destroyer

    attr_reader :shipping_rate

    def initialize(shipping_rate)
      @shipping_rate = shipping_rate
    end

    def destroy
      shipping_rate.adjustments.map(&:delete)
      shipping_rate.delete
    end

  end
end
