require_dependency 'spree/calculator'

module Spree
  class Calculator::FlatRate < Calculator
    preference :amount_in_gbp, :decimal, default: 0
    preference :amount_in_eur, :decimal, default: 0
    preference :amount_in_usd, :decimal, default: 0

    def self.description
      Spree.t(:flat_rate_per_order)
    end

    def compute(object=nil)
      return 0 if object.nil? || object.currency.nil?
      
      preferred_amount_in_currency = "preferred_amount_in_" + object.currency.downcase
      self.send(preferred_amount_in_currency)
    end
  end
end
