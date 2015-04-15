module Spree
  class ShippingManifestService
    # shipping manifest service
    class ShippingCosts < ActiveInteraction::Base
      model :order, class: "Spree::Order"

      def execute
        cost = shipping_coster(order.shipments).total
        BigDecimal.new(cost)
      end

      private

      def shipping_coster(shipments)
        ::Shipping::Coster.new(shipments)
      end
    end
  end
end
