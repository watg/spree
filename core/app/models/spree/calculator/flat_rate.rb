require_dependency 'spree/calculator'

module Spree
  class Calculator::FlatRate < Calculator

    def self.default_amount
      hash = {}
      Spree::Promotion::Rules::ItemTotal.currencies.each do |preferred_currency|
        hash[preferred_currency] ||= 0
      end
      hash
    end

    preference :amount, :hash, :default => default_amount

    def self.description
      Spree.t(:flat_rate_per_order)
    end

    def compute(object=nil)
      return 0 if object.nil? || object.currency.nil?
      self.preferred_amount[object.currency]
    end

  end
end
