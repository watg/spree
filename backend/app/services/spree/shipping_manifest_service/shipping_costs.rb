module Spree

  class ShippingManifestService::ShippingCosts < ActiveInteraction::Base

    model :order, class: 'Spree::Order'

    def execute
      cost = order.ship_total - order.shipping_discount
      BigDecimal.new(cost)
    end

  end

end
