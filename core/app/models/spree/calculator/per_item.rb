require_dependency 'spree/calculator'

module Spree
  class Calculator::PerItem < Calculator
    
    def self.default_amount
      Spree::Promotion::Rules::ItemTotal.currencies.map do |preferred_currency|
        hash = {}
        hash[:type] = :integer
        hash[:name] = preferred_currency
        hash[:value] = 0
        hash
      end
    end

    preference :amount, :array, :default => default_amount

    def self.description
      Spree.t(:flat_rate_per_item)
    end

    def compute(object=nil)
      return 0 if object.nil? || object.currency.nil?
      amount_in_currency = self.preferred_amount.find { |e| e[:name] == object.currency }
      return 0 if amount_in_currency.nil?
      amount_in_currency[:value] * object.line_items_without_gift_cards.reduce(0) do |sum, value|
        if matching_products.blank? || matching_products.include?(value.product)
          value_to_add = value.quantity
        else
          value_to_add = 0
        end
        sum + value_to_add
      end
    end

    # Returns all products that match this calculator, but only if the calculator
    # is attached to a promotion. If attached to a ShippingMethod, nil is returned.
    def matching_products
      # Regression check for #1596
      # Calculator::PerItem can be used in two cases.
      # The first is in a typical promotion, providing a discount per item of a particular item
      # The second is a ShippingMethod, where it applies to an entire order
      #
      # Shipping methods do not have promotions attached, but promotions do
      # Therefore we must check for promotions
      if self.calculable.respond_to?(:promotion)
        self.calculable.promotion.rules.map do |rule|
          rule.respond_to?(:products) ? rule.products : []
        end.flatten
      end
    end
  end
end
