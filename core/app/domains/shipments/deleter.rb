module Shipments
  class Deleter

    attr_reader :shipment

    def initialize(shipment)
      @shipment = shipment
    end

    def delete
      shipment.shipping_rates.each do |shipping_rate|
        ::ShippingRates::Deleter.new(shipping_rate).delete
      end
      shipment.delete
    end

  end
end
