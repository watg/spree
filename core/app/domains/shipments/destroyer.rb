module Shipments
  class Destroyer

    attr_reader :shipment

    def initialize(shipment)
      @shipment = shipment
    end

    def destroy
      shipment.shipping_rates.each do |shipping_rate|
        shipping_rate.adjustments.each do |adjustment|
          adjustment.destroy
        end
        shipping_rate.destroy
      end
      shipment.destroy
    end

  end
end
