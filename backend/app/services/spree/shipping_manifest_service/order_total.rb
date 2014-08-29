module Spree

  class ShippingManifestService::OrderTotal < ActiveInteraction::Base

    model :order, class: 'Spree::Order'

    def execute
      total = order.total
      total = total + gift_card_adjustments
      total = total - non_physical_amount
      BigDecimal.new(total)
    end

    private
    def gift_card_adjustments
      total = 0
      if order.adjustments.gift_card.any?
        amount_gift_cards = order.adjustments.gift_card.to_a.sum(&:amount).abs
        total += amount_gift_cards
      end
      total
    end

    def non_physical_amount
      total = 0
      digital_total_amount = order.line_items.digital.to_a.sum(&:amount)
      if digital_total_amount > 0
        total += digital_total_amount
      end
      total
    end

  end

end
