module Spree
  module Api
    module Dashboard
      module Warehouse
        # returns a formatted version of the number of orders sold today for the dashboard api
        class FormatTodayOrders
          def initialize(valid_orders)
            @orders = valid_orders.not_cancelled
          end

          def run
            today_orders = Spree::Api::Dashboard::Warehouse::FindTodayValidOrders.new(@orders).run
            { total: today_orders.count }
          end
        end
      end
    end
  end
end
