module Report
  module Domain
    class FirstOrderChecker

      attr_accessor :orders

      def initialize(orders)
        @orders = orders
      end

      def first_order?(order)
        first_order(order)
      end

      private

      def first_order(order)
        if order.user || order.email
          orders_complete = completed_orders(order.user, order.email)
          orders_complete.blank? || (orders_complete.order("completed_at asc").first == order)
        else
          false
        end
      end

      def completed_orders(user, email)
        if user
          orders.where("email = ? or user_id = ?", email, user.id)
        else
          orders.where("email = ?", email)
        end
      end

    end
  end
end
