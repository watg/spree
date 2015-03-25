module Spree
  module Api
    module Dashboard
      module Office
        # returns a formatted version of the number of orders sold today for the dashboard api
        class FormatTodayOrders
          def initialize(valid_orders)
            @orders = valid_orders
          end

          def run
            today_orders = Spree::Api::Dashboard::Office::FindTodayValidOrders.new(@orders).run
            { total: today_orders.count }
          end
        end
      end
    end
  end
end
