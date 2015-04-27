module Api
  module Dashboard
    module Warehouse
      # returns a formatted version of the number of orders sold today for the dashboard api
      class FormatTodayOrders
        def initialize(valid_orders = nil)
          valid_orders ||= Spree::Order.complete.not_cancelled
          @orders = valid_orders
        end

        def run
          today_orders = Api::Dashboard::Warehouse::FindTodayValidOrders.new(@orders).run
          { total: today_orders.count }
        end
      end
    end
  end
end