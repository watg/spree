module Api
  module Dashboard
    module Warehouse
      # returns a formatted version of the number of orders sold today
      # for the dashboard api divided in express and regular
      class FormatTodayOrdersByPriority
        def initialize(valid_orders = nil)
          valid_orders ||= Spree::Order.complete.not_cancelled
          @orders = valid_orders
        end

        def run
          today_orders = Api::Dashboard::Warehouse::FindTodayValidOrders.new(@orders).run
          express, normal = today_orders.partition { |o| o.express? }
          { express: express.count, normal: normal.count }
        end
      end
    end
  end
end