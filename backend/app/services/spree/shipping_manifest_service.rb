module Spree

  class ShippingManifestService < ActiveInteraction::Base
    model :order, class: 'Spree::Order'

    def execute
      rtn = {}
      rtn[:order_total] = order_total = compose(ShippingManifestService::OrderTotal, order: order)
      rtn[:shipping_costs] = shipping_costs = compose(ShippingManifestService::ShippingCosts, order: order)
      rtn[:terms_of_trade_code] = compose(ShippingManifestService::TermsOfTrade, order: order)
      rtn[:unique_products] = compose(
        ShippingManifestService::UniqueProducts,
        order: order,
        order_total: order_total,
        shipping_costs: shipping_costs
      )
      rtn
    end

  end

end
