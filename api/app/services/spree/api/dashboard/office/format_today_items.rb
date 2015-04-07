module Spree
  module Api
    module Dashboard
      module Office
        # returns a formatted version of the number of items sold today for the dashboard api
        class FormatTodayItems
          def initialize(valid_orders = nil)
            valid_orders ||= Spree::Order.complete.not_cancelled
            @orders = valid_orders
          end

          def run
            today_orders = Spree::Api::Dashboard::Office::FindTodayValidOrders.new(@orders).run
            {
              total: Spree::LineItem
                .joins(:order)
                .merge(today_orders)
                .to_a.map(&:quantity)
                .reduce(:+)
            }
          end
        end
      end
    end
  end
end
