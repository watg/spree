module Spree
  module Stock
    class Estimator
      attr_reader :order, :currency

      def initialize(order)
        @order = order
        @currency = order.currency
      end

      def shipping_rates(package, frontend_only = true)
        shipping_rates = calculate_shipping_rates(package)

        unless shipping_rates.empty?
          available_rates = shipping_rates.clone
          available_rates.select! { |rate| rate.shipping_method.frontend? } if frontend_only
          choose_default_shipping_rate(available_rates)
        end

        sort_shipping_rates(shipping_rates)
      end

      private
      def choose_default_shipping_rate(shipping_rates)
        shipping_rates.min_by(&:cost).selected = true
      end

      def sort_shipping_rates(shipping_rates)
        shipping_rates.sort_by!(&:cost)
      end

      def calculate_shipping_rates(package)
        shipping_methods(package).map do |shipping_method|
          cost = shipping_method.calculator.compute(package)
          shipping_method.shipping_rates.new(cost: cost) if cost
        end.compact
      end

      def shipping_methods(package)
        package.shipping_methods.select do |ship_method|
          calculator = ship_method.calculator
          calculator.available?(package) &&
          ship_method.include?(order.ship_address) &&
          (calculator.preferences[:currency].nil? ||
           calculator.preferences[:currency] == currency)
        end
      end
    end
  end
end
