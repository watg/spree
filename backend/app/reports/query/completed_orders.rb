module Report
  module Query
    class CompletedOrders

      COMPLETE_FOR_REPORTING = %w(complete resumed warehouse_on_hold customer_service_on_hold)
      PAYMENT_METHODS = ['PayPal', 'Credit Card']
      ORDER_TYPES = %(regular)

      attr_accessor :relation, :order_types

      def initialize(params = {})
        @relation = params.fetch(:orders, Spree::Order)
        @order_types = params.fetch(:order_types, ORDER_TYPES)
      end

      def query
        relation.complete.where(state: COMPLETE_FOR_REPORTING).
          joins(:order_type, payments: [:payment_method]).
          merge(Spree::OrderType.where(name: order_types)).
          merge(Spree::PaymentMethod.where(name: PAYMENT_METHODS)).uniq
      end

      def sql
        query.to_sql
      end

    end
  end
end
