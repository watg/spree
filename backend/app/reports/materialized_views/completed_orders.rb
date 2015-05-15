module Report
  module View
    class CompletedOrders

      NAME = "completed_orders_view"
      # For completed orders will need to move out
      COMPLETE_FOR_REPORTING = %w(complete resumed warehouse_on_hold customer_service_on_hold)
      PAYMENT_METHODS = ['PayPal', 'Credit Card']
      ORDER_TYPE = %(regular)

      def name
        NAME
      end

      def sql
        completed_orders_sql = completed_orders.to_sql
        "CREATE MATERIALIZED VIEW #{name} as #{completed_orders_sql}"
      end
      
      private

      def completed_orders
        Spree::Order.complete.where(state: COMPLETE_FOR_REPORTING).
          joins(:order_type, payments: [:payment_method]).
          merge(Spree::OrderType.where(name: ORDER_TYPE)).
          merge(Spree::PaymentMethod.where(name: PAYMENT_METHODS)).uniq
      end

    end
  end
end
