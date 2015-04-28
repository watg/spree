module Orders
  # recalculate delivery and shipment promotions when switching between delivery methods
  class RecalculateDeliveryService < ActiveInteraction::Base
    model :order, class: "Spree::Order"

    def run
      order.recalculate_shipping if order.state == "delivery"
    end
  end
end
