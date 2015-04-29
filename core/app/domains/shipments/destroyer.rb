module Shipments
  class Destroyer

    attr_reader :shipment

    def initialize(shipment)
      @shipment = shipment
    end

    def destroy
      shipment.shipping_rates.each do |shipping_rate|
        ::ShippingRates::Destroyer.new(shipping_rate).destroy
      end
      shipment.delete
    end

  end
end
