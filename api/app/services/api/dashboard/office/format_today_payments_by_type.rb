module Api
  module Dashboard
    module Office
      # returns a formatted version of the todays payments by type for the dashboard api
      class FormatTodayPaymentsByType
        def initialize(valid_orders = nil)
          valid_orders ||= Spree::Order.complete.not_cancelled
          @orders = valid_orders
        end

        def run
          data = grouped_orders_by_payment_type.map do |key, orders|
            { key => orders.count }
          end
          Hash[*data.map(&:to_a).flatten].sort_by { |_name, value| - value }
        end

        private

        def grouped_orders_by_payment_type
          today_orders.group_by do |order|
            order.payments.map{ |p| p.payment_method.name }.uniq.sort.join(" / ")
          end
        end

        def today_orders
          Api::Dashboard::Office::FindTodayValidOrders.new(@orders).run
        end
      end
    end
  end
end
