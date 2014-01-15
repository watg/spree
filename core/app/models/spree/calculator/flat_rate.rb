require_dependency 'spree/calculator'

module Spree
  class Calculator::FlatRate < Calculator

    def self.default_amount
      Spree::Config[:supported_currencies].map do |preferred_currency|
        hash = {}
        hash[:type] = :decimal
        hash[:name] = preferred_currency
        hash[:value] = 0
        hash
      end
    end

    preference :amount, :array, :default => default_amount

    def self.description
      Spree.t(:flat_rate_per_order)
    end

    def compute(object=nil)
      return 0 if object.nil? || object.currency.nil?
      amount_in_currency = self.preferred_amount.find { |e| e[:name] == object.currency }
      return 0 if amount_in_currency.nil?
      BigDecimal.new(amount_in_currency[:value].to_s).round(2, BigDecimal::ROUND_HALF_UP)
    end

  end
end
