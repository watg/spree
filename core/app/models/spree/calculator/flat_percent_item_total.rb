require_dependency 'spree/calculator'

module Spree
  class Calculator::FlatPercentItemTotal < Calculator
    preference :flat_percent, :decimal, default: 0

    def self.description
      Spree.t(:flat_percent)
    end

    def compute(object)
      return unless object.present? and object.respond_to?(:item_total)
      item_total = item_total_for(object)
      value = item_total * BigDecimal(self.preferred_flat_percent.to_s) / 100.0
      (value * 100).round.to_f / 100
    end

    def item_total_for(object)
      method_name = (object.kind_of?(Spree::Order) && object.has_gift_card? ? :item_total_without_gift_cards : :item_total)
      object.send(method_name)
    end
  end
end
